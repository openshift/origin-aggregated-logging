#!/bin/bash

set -euo pipefail

tmpworkdir=${WORKDIR:-$( mktemp --tmpdir -d logging-build-XXXXXXXXXX )}
function cleanup() {
  return_code=$?
  set +e
  if [ "${return_code:-1}" -eq 0 ] ; then
    echo Success
  else
    echo Failure - error code $return_code
  fi
  if [ -z "${WORKDIR:-}" ] ; then
    rm -rf "${tmpworkdir:-nosuchfileordirectory}"
  fi
  if [ -n "${forwarding_pid:-}" ] ; then
    kill -15 ${forwarding_pid}
  fi
  exit "${return_code}"
}
trap "cleanup" EXIT

function image_is_ubi() {
  if [ -f $1 ] ; then
    # if $1 is a file, assume a Dockerfile with a FROM - otherwise,
    # it is an image name
    grep -q "^FROM registry.svc.ci.openshift.org/ocp/[1-9].[0-9][0-9]*" $1
  else
    echo "$1" | grep -q "registry.svc.ci.openshift.org/ocp/[1-9].[0-9][0-9]*"
  fi
}

function image_needs_private_repo() {
  # dockerfile is arg $1
  image_is_ubi $1 || \
    grep -q "^FROM registry.svc.ci.openshift.org/openshift/origin-v4.[0-9][0-9]*:base" $1
}

CI_REGISTRY=${CI_REGISTRY:-registry.svc.ci.openshift.org}
CI_CLUSTER_NAME=${CI_CLUSTER_NAME:-api-ci-openshift-org:443}
CUSTOM_IMAGE_TAG=${CUSTOM_IMAGE_TAG:-latest}

function get_context_for_cluster() {
  set +o pipefail > /dev/null
  oc config get-contexts | awk -F'[* ]+' -v clname="$1" '$3 == clname {print $2; exit}'
  set -o pipefail > /dev/null
}

# get credentials needed to authenticate to $CI_REGISTRY
# requires `oc` and requires user to have recently `oc login` to the $CI_CLUSTER_NAME cluster
# NOTE: cluster name != cluster hostname!!
function login_to_ci_registry() {
  local savekc=""
  local savectx=$( oc config current-context )
  local cictx=$( get_context_for_cluster $CI_CLUSTER_NAME )
  if [ "$savectx" == "$cictx" ]; then
    echo WARNING: cluster context and ci context are identical "$cictx"
    oc config get-contexts
  fi
  rc=0
  if [ -z "$cictx" ] ; then
    # try again without KUBECONFIG
    savekc=${KUBECONFIG:-}
    unset KUBECONFIG
    savectx=$( oc config current-context )
    cictx=$( get_context_for_cluster $CI_CLUSTER_NAME )
  fi
  if [ -z "$cictx" ] ; then
    echo ERROR: login_to_ci_registry: you must oc login to the server for cluster $CI_CLUSTER_NAME
    echo oc config get-contexts does not list cluster $CI_CLUSTER_NAME
    rc=1
  else
    oc config use-context "$cictx"
    local username=$( oc whoami )
    local token=$( oc whoami -t 2> /dev/null || : )
    if [ -z "$token" -o -z "$username" ] ; then
      echo ERROR: no username or token for context "$cictx"
      echo your credentials may have expired
      echo please oc login to the server for cluster $CI_CLUSTER_NAME
      rc=1
    else
      podman login -u "$username" -p "$token" $CI_REGISTRY
    fi
  fi
  if [ -n "$savectx" ] ; then
    oc config use-context "$savectx"
  fi
  if [ -n "$savekc" ] ; then
    export KUBECONFIG=$savekc
  fi
  return $rc
}

function pull_ubi_if_needed() {
  # $1 is dockerfile - first, extract images
  local images=$( awk '/^FROM / {print $2}' $1 | sort -u )
  local image
  for image in $images ; do
    if image_is_ubi "$image" ; then
      login_to_ci_registry
    fi
    podman pull "$image"
  done
}

# to build using internal/private yum repos, specify
# INTERNAL_REPO_DIR=/path/to/dir/
# where /path/to/dir/ contains the yum .repo files, and
# any private key pem files needed - this dir will be
# mounted into the builder as /etc/yum.repos.d/
INTERNAL_REPO_DIR=${INTERNAL_REPO_DIR:-}
function get_private_repo_dir() {
  if [ -z "${INTERNAL_REPO_DIR:-}" ] ; then
    pushd $tmpworkdir > /dev/null
    if [ ! -d repos ] ; then
      mkdir repos
      if [ -n "${GOPATH:-}" -a -f ${GOPATH:-}/src/github.com/openshift/shared-secrets/mirror/ops-mirror.pem ] ; then
        cp $GOPATH/src/github.com/openshift/shared-secrets/mirror/ops-mirror.pem repos
      else
        if [ ! -d shared-secrets ] ; then
          git clone -q git@github.com:openshift/shared-secrets.git
        fi
        cp shared-secrets/mirror/ops-mirror.pem repos
      fi
      local releasedir=${GOPATH:-nosuchdir}/src/github.com/openshift/release
      if [ -d $releasedir ] ; then
        pushd $releasedir > /dev/null
        git pull -q
        popd > /dev/null
      else
        if [ ! -d release ] ; then
            git clone -q https://github.com/openshift/release
        fi
        releasedir=release
      fi
      local repofile
      for repofile in \
        $releasedir/core-services/release-controller/_repos/ocp-4.3-default.repo \
        $releasedir/core-services/release-controller/_repos/ocp-4.2-default.repo \
        $releasedir/core-services/release-controller/_repos/ocp-4.1-default.repo ; do
        if [ -f $repofile ] ; then
            cp $repofile repos
            break
        fi
      done
      touch repos/redhat.repo
      chmod 0444 repos/redhat.repo
      sed -i -e 's,^sslclientkey.*$,sslclientkey = /etc/yum.repos.d/ops-mirror.pem,' \
              -e 's,^sslclientcert.*$,sslclientcert = /etc/yum.repos.d/ops-mirror.pem,' repos/*.repo
    fi
    INTERNAL_REPO_DIR=$( pwd )/repos
    popd > /dev/null
  elif [ ! -f $INTERNAL_REPO_DIR/ops-mirror.pem ] || [ ! -f $INTERNAL_REPO_DIR/ocp-4.3-default.repo -a ! -f $INTERNAL_REPO_DIR/ocp-4.2-default.repo -a ! -f $INTERNAL_REPO_DIR/ocp-4.1-default.repo ] ; then
    echo ERROR: $INTERNAL_REPO_DIR missing one of ops-mirror.pem or ocp-4.3-default.repo and ocp-4.2-default.repo and ocp-4.1-default.repo
    exit 1
  fi
  echo $INTERNAL_REPO_DIR
}

function login_to_registry() {
  local savectx=$( oc config current-context )
  local token=""
  local username=""
  if [ -n "${PUSH_USER:-}" -a -n "${PUSH_PASSWORD:-}" ] ; then
    username=$PUSH_USER
    if [ "$username" = "kube:admin" ] ; then
      username=kubeadmin
    fi
    oc login -u "$username" -p "$PUSH_PASSWORD" > /dev/null
    token=$( oc whoami -t 2> /dev/null || : )
    oc config use-context "$savectx"
  else
    # see if current context has a token
    token=$( oc whoami -t 2> /dev/null || : )
    if [ -n "$token" ] ; then
      username=$( oc whoami )
    else
      # get the first user with a token
      token=$( oc config view -o go-template='{{ range .users }}{{ if .user.token }}{{ print .user.token }}{{ end }}{{ end }}' )
      if [ -n "$token" ] ; then
        username=$( oc config view -o go-template='{{ range .users }}{{ if .user.token }}{{ print .name }}{{ end }}{{ end }}' )
        # username is in form username/cluster - strip off the cluster part
        username=$( echo "$username" | sed 's,/.*$,,' )
      fi
    fi
    if [ -z "$token" ] ; then
      echo ERROR: could not determine token to use to login to "$1"
      echo please do \`oc login -u username -p password\` to create a context with a token
      echo OR
      echo set \$PUSH_USER and \$PUSH_PASSWORD and run this script again
      return 1
    fi
    if [ "$username" = "kube:admin" ] ; then
      username=kubeadmin
    fi
  fi
  podman login --tls-verify=false -u "$username" -p "$token" "$1" > /dev/null
}

function push_image() {
  podman push --tls-verify=false "$1" "$2"
}

function switch_to_admin_user() {
  # make sure we are using the admin credentials for the remote repo
  if [ -z "${KUBECONFIG:-}" ] ; then
    echo WARNING: KUBECONFIG is not set - assuming you have set credentials
    echo via ~/.kube/config or otherwise
  fi

  if ! oc auth can-i view pods/log -n default > /dev/null 2>&1 ; then
    local adminname
    local oldcontext=$( oc config current-context )
    # see if there is already an admin context in the kubeconfig
    for adminname in admin system:admin kube:admin ; do
      if oc config use-context $adminname > /dev/null 2>&1 ; then
        break
      fi
    done
    if oc auth can-i view pods/log -n default > /dev/null 2>&1 ; then
      echo INFO: switched from context [$oldcontext] to [$(oc config current-context)]
    else
      echo ERROR: could not get an admin context to use - make sure you have
      echo set KUBECONFIG or ~/.kube/config correctly
      oc config use-context $oldcontext
      exit 1
    fi
  fi
}

tag_prefix="${OS_IMAGE_PREFIX:-"openshift/origin-"}"

name_suf="6"
curbranch=$( git rev-parse --abbrev-ref HEAD )

IMAGE_BUILDER=${IMAGE_BUILDER:-podman}
IMAGE_BUILDER_OPTS=${IMAGE_BUILDER_OPTS:-}

# NOTE: imagestream/buildconfig builds do not work unless we
# can find a safe and secure way to mount the private key
# into the builder running in a public cloud . . .
if [ "${USE_IMAGE_STREAM:-false}" = true ] ; then
    oc -n openshift process \
        -p LOGGING_FORK_URL=https://github.com/${LOGGING_GITHUB_REPO:-openshift}/origin-aggregated-logging \
        -p LOGGING_FORK_BRANCH=${LOGGING_FORK_BRANCH:-master} \
        -f hack/templates/dev-builds.yaml | \
      oc -n openshift create -f -
    # wait for is and bc
    names="elasticsearch${name_suf:-} kibana${name_suf:-} fluentd curator5 eventrouter"
    for ii in $(seq 1 10) ; do
        notfound=
        for obj in $names ; do
            if oc -n openshift get bc logging-$obj > /dev/null 2>&1 && \
               oc -n openshift get is logging-$obj > /dev/null 2>&1 ; then
                : ; # found
            else
                notfound=1
            fi
        done
        if [ -z "$notfound" ] ; then
            break
        fi
        sleep 1
    done
    if [ $ii = 10 ] ; then
        echo ERROR: timeout waiting for logging buildconfigs and imagestreams to be available
        exit 1
    fi
    # build and wait
    for obj in $names ; do
        oc -n openshift logs -f bc/logging-$obj
    done
    exit 0
fi

# first of pair is name of subdir for component
# second is base name of image to build
# e.g. 'fluentd logging-fluentd' means build the image from the fluentd/
# subdir, and name the image something/logging-fluentd:${tag}
REPO_IMAGE_LIST="${REPO_IMAGE_LIST:-fluentd logging-fluentd elasticsearch logging-elasticsearch${name_suf:-} \
    kibana logging-kibana${name_suf:-} curator logging-curator${name_suf:-} \
    eventrouter logging-eventrouter logging-ci-test-runner logging-ci-test-runner}"

if [ "${PUSH_ONLY:-false}" = false ] ; then
  dir=""
  img=""
  for item in $REPO_IMAGE_LIST; do
    if [ -z "$dir" ] ; then dir=$item ; continue ; fi
    img=$item
    if [ $img = logging-ci-test-runner ] ; then
      dfpath=openshift/ci-operator/build-image/Dockerfile.full
      dir=.
      fullimagename=openshift/logging-ci-test-runner:${CUSTOM_IMAGE_TAG}
    else
      dfpath=$dir/Dockerfile
      fullimagename="${tag_prefix}$img:${CUSTOM_IMAGE_TAG}"
    fi
    pull_ubi_if_needed $dfpath
    if image_needs_private_repo $dfpath ; then
      repodir=$( get_private_repo_dir )
      mountarg="-v $repodir:/etc/yum.repos.d/"
    else
      mountarg=""
    fi

    suffix=""
    if [ "$img" = "logging-elasticsearch6" ] ; then
        suffix=".origin"
    fi

    echo "----------------------------------------------------------------------------------------------------------------"
    echo "-                                                                                                              -"
    echo "Building image $img - this may take a few minutes until you see any output..."
    echo "-                                                                                                              -"
    echo "----------------------------------------------------------------------------------------------------------------"
    $IMAGE_BUILDER build $IMAGE_BUILDER_OPTS $mountarg -f $dfpath$suffix -t "$fullimagename" $dir
    dir=""
    img=""
  done
fi

# we have to be an admin user to proceed from here
switch_to_admin_user

LOCAL_PORT=${LOCAL_PORT:-5000}
REGISTRY_PORT=${REGISTRY_PORT:-5000}

echo "Setting up port-forwarding to remote image-registry ..."
oc -n openshift-image-registry port-forward service/image-registry ${LOCAL_PORT}:${REGISTRY_PORT} > $tmpworkdir/pf-oal.log 2>&1 &
forwarding_pid=$!

for ii in $(seq 1 60) ; do
  if [ "$(curl -sk -w '%{response_code}\n' https://localhost:5000 || :)" = 200 ] ; then
    break
  fi
  sleep 1
done
if [ $ii = 60 ] ; then
  echo ERROR: timeout waiting for port-forward to be available
  exit 1
fi

login_to_registry "127.0.0.1:${LOCAL_PORT}"

for image in "${tag_prefix}logging-fluentd" "${tag_prefix}logging-elasticsearch${name_suf:-}" \
  "${tag_prefix}logging-kibana${name_suf:-}" "${tag_prefix}logging-curator${name_suf:-}" \
  "${tag_prefix}logging-eventrouter" \
  "openshift/logging-ci-test-runner" ; do
  remote_image="127.0.0.1:${REGISTRY_PORT}/$image"

  podman tag ${image}:${CUSTOM_IMAGE_TAG} ${remote_image}:${CUSTOM_IMAGE_TAG}

  echo "----------------------------------------------------------------------------------------------------------------"
  echo "-                                                                                                              -"
  echo "Pushing image ${image}:${CUSTOM_IMAGE_TAG} to ${remote_image}:${CUSTOM_IMAGE_TAG}..."
  echo "-                                                                                                              -"
  echo "----------------------------------------------------------------------------------------------------------------"

  rc=1
  for ii in $( seq 1 5 ) ; do
    if push_image ${image}:${CUSTOM_IMAGE_TAG} ${remote_image}:${CUSTOM_IMAGE_TAG} ; then
      rc=0
      break
    fi
    echo push failed - retrying
    rc=1
    sleep 1
  done
  if [ $rc = 1 -a $ii = 5 ] ; then
    echo ERROR: giving up push of ${image}:${CUSTOM_IMAGE_TAG} to ${remote_image}:${CUSTOM_IMAGE_TAG} after 5 tries
    exit 1
  fi
done

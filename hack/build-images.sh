#!/bin/bash

source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

function cleanup() {
    return_code=$?
    os::util::describe_return_code "${return_code}"
    exit "${return_code}"
}
trap "cleanup" EXIT

# to build using internal/private yum repos, specify
# INTERNAL_REPO_DIR=/path/to/dir/
# where /path/to/dir/ contains the yum .repo files, and
# any private key pem files needed - this dir will be
# mounted into the builder as /etc/yum.repos.d/
INTERNAL_REPO_DIR=${INTERNAL_REPO_DIR:-}
mountarg=""
rsyslog_mountarg=""
if [ "$INTERNAL_REPO_DIR" ] ; then
    # none of the other images support this yet
    rsyslog_mountarg="-mount $INTERNAL_REPO_DIR:/etc/yum.repos.d/"
fi

tag_prefix="${OS_IMAGE_PREFIX:-"openshift/origin-"}"
docker_suffix='.centos7'
# use .fedora if you really must build the fedora version
rsyslog_docker_suffix=${RSYSLOG_DOCKER_SUFFIX:-}
if [ "${RELEASE_STREAM:-}" = 'prod' ] ; then
  docker_suffix=''
  rsyslog_docker_suffix=''
fi
dockerfile="Dockerfile${docker_suffix}"
rsyslog_dockerfile="Dockerfile${rsyslog_docker_suffix}"

name_suf="5"
curbranch=$( git rev-parse --abbrev-ref HEAD )

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
    names="elasticsearch${name_suf:-} kibana${name_suf:-} fluentd curator${name_suf:-} eventrouter rsyslog"
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

if [ "${PUSH_ONLY:-false}" = false ] ; then
  OS_BUILD_IMAGE_ARGS="$mountarg -f fluentd/${dockerfile}" os::build::image "${tag_prefix}logging-fluentd"             fluentd
  OS_BUILD_IMAGE_ARGS="$mountarg -f elasticsearch/${dockerfile}" os::build::image "${tag_prefix}logging-elasticsearch${name_suf:-}" elasticsearch
  OS_BUILD_IMAGE_ARGS="$mountarg -f kibana/${dockerfile}" os::build::image "${tag_prefix}logging-kibana${name_suf:-}"               kibana
  OS_BUILD_IMAGE_ARGS="$mountarg -f curator/${dockerfile}" os::build::image "${tag_prefix}logging-curator${name_suf:-}"             curator
  OS_BUILD_IMAGE_ARGS="$mountarg -f eventrouter/${dockerfile}" os::build::image "${tag_prefix}logging-eventrouter"     eventrouter
  OS_BUILD_IMAGE_ARGS="$rsyslog_mountarg -f rsyslog/${rsyslog_dockerfile}" os::build::image "${tag_prefix}logging-rsyslog"     rsyslog
fi

if [ "${REMOTE_REGISTRY:-false}" = false ] ; then
    exit 0
fi

registry_namespace=openshift-image-registry
registry_svc=image-registry
registry_host=$registry_svc.$registry_namespace.svc
if ! oc get namespace $registry_namespace ; then
    registry_namespace=default
    registry_svc=docker-registry
    # use ip instead
    registry_host=$(oc get svc $registry_svc -n $registry_namespace -o jsonpath={.spec.clusterIP})
fi

registry_port=$(oc get svc $registry_svc -n $registry_namespace -o jsonpath={.spec.ports[0].port})
if [ $registry_namespace = openshift-image-registry ] ; then
    # takes pod name in 4.0
    port_fwd_obj=$( oc get pods -n $registry_namespace | awk '/^image-registry-/ {print $1}' )
else
    # takes service in 3.11
    port_fwd_obj="service/$registry_svc"
fi

LOCAL_PORT=${LOCAL_PORT:-5000}

echo "Setting up port-forwarding to remote $registry_svc ..."
oc --loglevel=9 port-forward $port_fwd_obj -n $registry_namespace ${LOCAL_PORT}:${registry_port} > pf.log 2>&1 &
forwarding_pid=$!

trap "kill -15 ${forwarding_pid}" EXIT
for ii in $(seq 1 10) ; do
    if [ "$(curl -sk -w '%{response_code}\n' https://localhost:5000 || :)" = 200 ] ; then
        break
    fi
    sleep 1
done
if [ $ii = 10 ] ; then
    echo ERROR: timeout waiting for port-forward to be available
    exit 1
fi

ADMIN_USER=${ADMIN_USER:-$( oc whoami )}
if [ "$ADMIN_USER" = "kube:admin" ] ; then
    ADMIN_USER=kubeadmin
fi
docker login 127.0.0.1:${LOCAL_PORT} -u "$ADMIN_USER" -p $(oc whoami -t)

push_image() {
    docker push "$2"
}
if type -p skopeo > /dev/null 2>&1 ; then
    push_image() {
        skopeo copy --dest-tls-verify=false docker-daemon:"$1" docker://"$2"
    }
fi

for image in "${tag_prefix}logging-fluentd" "${tag_prefix}logging-elasticsearch${name_suf:-}" \
  "${tag_prefix}logging-kibana${name_suf:-}" "${tag_prefix}logging-curator${name_suf:-}" \
  "${tag_prefix}logging-eventrouter" "${tag_prefix}logging-rsyslog" ; do
  remote_image="127.0.0.1:${registry_port}/$image"
  docker tag ${image} ${remote_image}
  echo "Pushing image ${image} to ${remote_image}..."
  rc=1
  for ii in $( seq 1 5 ) ; do
    if push_image ${image}:latest ${remote_image}:latest ; then
      rc=0
      break
    fi
    echo push failed - retrying
    rc=1
    sleep 1
  done
  if [ $rc = 1 -a $ii = 5 ] ; then
    echo ERROR: giving up push of ${image}:latest to ${remote_image}:latest after 5 tries
    exit 1
  fi
done

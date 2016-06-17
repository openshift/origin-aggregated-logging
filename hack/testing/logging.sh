#!/bin/bash
#
# This script is run in conjunction with origin automated testing.
# It is intended to run from the openshift/origin/test/extended
# directory, and launched by `vagrant test-origin -e logging`
#
# This scripts starts the OpenShift server with a default configuration.
# The OpenShift Docker registry and router are installed.
# It will run the logging tests

set -o errexit
set -o nounset
set -o pipefail

STARTTIME=$(date +%s)
# assume this script is being run from openshift/origin-aggregated-logging/hack/testing, and
# origin is checked out in openshift/origin
OS_ROOT=${OS_ROOT:-$(dirname "${BASH_SOURCE}")/../../origin}
# use absolute path
pushd $OS_ROOT
OS_ROOT=`pwd`
popd
GIT_URL=${GIT_URL:-https://github.com/openshift/origin-aggregated-logging}
GIT_BRANCH=${GIT_BRANCH:-master}
# assume this script is being run from openshift/origin-aggregated-logging/hack/testing
OS_O_A_L_DIR=${OS_O_A_L_DIR:-$(dirname "${BASH_SOURCE}")/../..}
# use absolute path
pushd $OS_O_A_L_DIR
OS_O_A_L_DIR=`pwd`
popd
USE_LOGGING_DEPLOYER=
USE_LOGGING_DEPLOYER_SCRIPT=
ENABLE_OPS_CLUSTER=${ENABLE_OPS_CLUSTER:-false}
DEBUG_FAILURES=${DEBUG_FAILURES:-false}
USE_LOCAL_SOURCE=${USE_LOCAL_SOURCE:-false}
TEST_PERF=${TEST_PERF:-false}
ES_VOLUME=${ES_VOLUME:-/var/lib/es}
ES_OPS_VOLUME=${ES_OPS_VOLUME:-/var/lib/es-ops}

# use a few tools from the deployer
source "$OS_O_A_L_DIR/deployer/scripts/util.sh"

# include all the origin test libs we need
for lib in "${OS_ROOT}"/hack/{util.sh,text.sh} \
           "${OS_ROOT}"/hack/lib/*.sh "${OS_ROOT}"/hack/lib/**/*.sh
do source "$lib"; done

os::log::install_errexit
os::util::environment::setup_time_vars

cd "${OS_ROOT}"

os::build::setup_env

os::test::junit::declare_suite_start 'logging'

function cleanup()
{
    out=$?
    echo
    if [ $out -ne 0 ]; then
        echo "[FAIL] !!!!! Test Failed !!!!"
    else
        echo "[INFO] Test Succeeded"
    fi
    echo

    os::test::junit::declare_suite_end
    os::test::junit::reconcile_output
    if [ "$DEBUG_FAILURES" = "true" ] ; then
        echo debug failures
        sleep 54321 || echo debugging done - continuing
    fi
    cleanup_openshift
    echo "[INFO] Exiting at " `date`
    ENDTIME=$(date +%s); echo "$0 took $(($ENDTIME - $STARTTIME)) seconds"
    exit $out
}

function wait_for_latest_build_complete() {

  interval=30
  waittime=120

  local bc=$1
  local lastVersion=$(oc get bc $bc -o jsonpath='{.status.lastVersion}')
  local status

  for (( i = 1; i <= $waittime; i++ )); do
    status=$(oc get build/$bc-$lastVersion -o jsonpath='{.status.phase}')
    case $status in
      "Complete")
        return 0
        ;;
      "Failed")
        return 1
        ;;
      "Pending"|"Running")
        sleep $interval
        ;;
    esac
  done

  return 1
}

function wait_for_new_builds_complete() {

  retries=30
  for bc in $(oc get bc -l logging-infra -o jsonpath='{.items[*].metadata.name}'); do

    for (( i = 1; i <= retries; i++ )); do

      wait_for_latest_build_complete "$bc" && break

      [[ $i -eq $retries ]] && return 1

      oc delete builds -l buildconfig=$bc

      if [ "$USE_LOCAL_SOURCE" = false ] ; then
          oc start-build $bc
      else
          oc start-build --from-dir $OS_O_A_L_DIR $bc
      fi
    done

  done

  return 0
}

function wait_for_builds_complete()
{
    waittime=1800 # seconds - 30 minutes
    interval=30
    complete=0
    while [ $waittime -gt 0 -a $complete = 0 ] ; do
        # all lines must have $4 == "Complete"
        complete=`oc get builds | awk '$4 == "STATUS" || $4 == "Complete" {complete++}; END {print NR == complete}'`
        if [ $complete = 1 ] ; then
            echo Builds are complete
            break
        fi
        # restart failed builds
        # get a list of the new failures
        curfailedbuilds=`oc get builds | awk '$4 == "Failed" {print $1}'`
        for build in $curfailedbuilds ; do
            # get the bc
            bc=`oc get build $build --template='{{.metadata.labels.buildconfig}}'`
            # see if there is a build in progress for this bc
            statuses=`oc describe bc $bc | awk -v pre=$bc '$1 ~ pre {print $2}'`
            needbuild=0
            for status in $statuses ; do
                case $status in
                "running"|"complete"|"pending")
                    echo build in progress for $bc - delete failed build $build
                    # delete the failed build - otherwise it will show up in the list and
                    # the main loop will never Complete
                    oc delete build $build
                    needbuild=0
                    break
                    ;;
                "failed")
                    # if the build failed, there will be at least 1 failed status
                    # if there is another build running or complete, it will be
                    # detected above
                    needbuild=1
                    ;;
                esac
            done
            # if we are here and needbuild=1, there were no running or complete builds
            if [ $needbuild = "1" ] ; then
                # start a new build
                if [ "$USE_LOCAL_SOURCE" = false ] ; then
                    oc start-build $bc
                else
                    oc start-build --from-dir $OS_O_A_L_DIR $bc
                fi
            fi
        done
        sleep $interval
        waittime=`expr $waittime - $interval`
    done
    if [ $complete = 0 ] ; then
        echo error builds are not complete
        oc get builds
        return 1
    fi
    return 0
}

function get_running_pod() {
    # $1 is component for selector
    oc get pods -l component=$1 | awk -v sel=$1 '$1 ~ sel && $3 == "Running" {print $1}'
}

function get_latest_pod() {

  label=$1

  local times=(`oc get pods -l $label -o jsonpath='{.items[*].metadata.creationTimestamp}' | xargs -n1 | sort -r | xargs`)
  local pod=$(oc get pods -l $label -o jsonpath="{.items[?(@.metadata.creationTimestamp==\"${times[0]}\")].metadata.name}")

  echo $pod
}

trap "exit" INT TERM
trap "cleanup" EXIT

echo "[INFO] Starting logging tests at " `date`

ensure_iptables_or_die
# override LOG_DIR and ARTIFACTS_DIR
export LOG_DIR=${LOG_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging/logs}
export ARTIFACT_DIR=${ARTIFACT_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging/artifacts}
os::util::environment::setup_all_server_vars "origin-aggregated-logging/"
os::util::environment::use_sudo
reset_tmp_dir

os::log::start_system_logger

export KUBELET_HOST=$(hostname)

configure_os_server
start_os_server

export KUBECONFIG="${ADMIN_KUBECONFIG}"

install_registry
wait_for_registry

######### logging specific code starts here ####################

### create and deploy the logging component pods ###
masterurlhack=",MASTER_URL=https://172.30.0.1:443"
OS_O_A_L_DIR=${OS_O_A_L_DIR:-$OS_ROOT/test/extended/origin-aggregated-logging}
os::cmd::expect_success "oadm new-project logging --node-selector=''"
os::cmd::expect_success "oc project logging"
os::cmd::expect_success "oc secrets new logging-deployer nothing=/dev/null"
os::cmd::expect_success "oc create -f $OS_O_A_L_DIR/deployer/deployer.yaml"
os::cmd::expect_success "oc new-app logging-deployer-account-template"
os::cmd::expect_success "oc policy add-role-to-user edit system:serviceaccount:logging:logging-deployer"
os::cmd::expect_success "oc policy add-role-to-user daemonset-admin system:serviceaccount:logging:logging-deployer"
os::cmd::expect_success "oadm policy add-cluster-role-to-user oauth-editor system:serviceaccount:logging:logging-deployer"
if [ -n "$USE_LOGGING_DEPLOYER" ] ; then
    imageprefix="docker.io/openshift/origin-"
elif [ -n "$USE_LOGGING_DEPLOYER_SCRIPT" ] ; then
    pushd $OS_O_A_L_DIR/deployer
    IMAGE_PREFIX="openshift/origin-" PROJECT=logging ./run.sh
    popd
    imageprefix=
else
    if [ "$USE_LOCAL_SOURCE" = "true" ] ; then
        build_filter() {
            # remove all build triggers
            sed "/triggers/d; /- type: .*Change/d"
        }
        post_build() {
            os::cmd::try_until_success "oc get imagestreamtag origin:latest" "$(( 1 * TIME_MIN ))"
            for bc in `oc get bc -o jsonpath='{.items[*].metadata.name}'` ; do
                oc start-build --from-dir $OS_O_A_L_DIR $bc
            done
        }
    else
        build_filter() {
            cat
        }
        post_build() {
            :
        }
    fi

    os::cmd::expect_success "oc process -o yaml \
       -f $OS_O_A_L_DIR/hack/templates/dev-builds.yaml \
       -v LOGGING_FORK_URL=$GIT_URL,LOGGING_FORK_BRANCH=$GIT_BRANCH \
       | build_filter | oc create -f -"
    post_build
    os::cmd::expect_success "wait_for_builds_complete"
    imageprefix=`oc get is | awk '$1 == "logging-deployment" {print gensub(/^([^/]*\/logging\/).*$/, "\\\1", 1, $2)}'`
    sleep 5
fi
pvc_params=""
if [ "$ENABLE_OPS_CLUSTER" = "true" ]; then
    if [ ! -d $ES_OPS_VOLUME ] ; then
        sudo mkdir -p $ES_OPS_VOLUME
        sudo chown 1000:1000 $ES_OPS_VOLUME
    fi
    os::cmd::expect_success "oc process -f $OS_O_A_L_DIR/hack/templates/pv-hostmount.yaml -v SIZE=10,PATH=${ES_OPS_VOLUME} | oc create -f -"
    pvc_params="-p ES_OPS_PVC_SIZE=10 -p ES_OPS_PVC_PREFIX=es-ops-pvc-" # deployer will create PVC
fi
# TODO: put this back to hostmount-anyuid once we've resolved the SELinux problem with that
# https://github.com/openshift/origin-aggregated-logging/issues/89
os::cmd::expect_success "oadm policy add-scc-to-user privileged system:serviceaccount:logging:aggregated-logging-fluentd"
sleep 5
os::cmd::expect_success "oadm policy add-cluster-role-to-user cluster-reader \
                      system:serviceaccount:logging:aggregated-logging-fluentd"
sleep 5
if [ ! -n "$USE_LOGGING_DEPLOYER_SCRIPT" ] ; then
    os::cmd::expect_success "oc new-app \
                          logging-deployer-template \
                          -p ENABLE_OPS_CLUSTER=$ENABLE_OPS_CLUSTER \
                          ${pvc_params} \
                          -p IMAGE_PREFIX=$imageprefix \
                          -p KIBANA_HOSTNAME=kibana.example.com \
                          -p ES_CLUSTER_SIZE=1 \
                          -p PUBLIC_MASTER_URL=https://localhost:8443${masterurlhack}"

    os::cmd::try_until_text "oc describe bc logging-deployment | awk '/^logging-deployment-/ {print \$2}'" "complete"
    os::cmd::try_until_text "oc get pods -l logging-infra=deployer" "Completed" "$(( 3 * TIME_MIN ))"
fi
if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
    # TODO: this shouldn't be necessary once SELinux problems are worked out
    # leave this at hostmount-anyuid once we've resolved the SELinux problem with that
    # https://github.com/openshift/origin-aggregated-logging/issues/89
    os::cmd::expect_success "oadm policy add-scc-to-user privileged \
         system:serviceaccount:logging:aggregated-logging-elasticsearch"
    # update the ES_OPS DC to be in the privileged context.
    # TODO: should not have to do that - should work the same as regular hostmount
    os::cmd::try_until_text "oc get dc -o name -l component=es-ops" "ops"
    ops_dc=$(oc get dc -o name -l component=es-ops) || exit 1
    os::cmd::expect_success "oc patch $ops_dc \
       -p '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"elasticsearch\",\"securityContext\":{\"privileged\": true}}]}}}}'"

    os::cmd::try_until_text "oc deploy $ops_dc --latest" "Started" "$(( 3 * TIME_MIN ))"
fi
# see if expected pods are running
os::cmd::try_until_text "oc get pods -l component=es" "Running" "$(( 3 * TIME_MIN ))"
os::cmd::try_until_text "oc get pods -l component=kibana" "Running" "$(( 3 * TIME_MIN ))"
os::cmd::try_until_text "oc get pods -l component=curator" "Running" "$(( 3 * TIME_MIN ))"
if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
    # make sure the expected PVC was created and bound
    os::cmd::try_until_text "oc get persistentvolumeclaim es-ops-pvc-1" "Bound" "$(( 1 * TIME_MIN ))"
    # make sure the expected pods are running
    os::cmd::try_until_text "oc get pods -l component=es-ops" "Running" "$(( 3 * TIME_MIN ))"
    os::cmd::try_until_text "oc get pods -l component=kibana-ops" "Running" "$(( 3 * TIME_MIN ))"
    os::cmd::try_until_text "oc get pods -l component=curator-ops" "Running" "$(( 3 * TIME_MIN ))"
fi

if [ -n "$ES_VOLUME" ] ; then
    if [ ! -d $ES_VOLUME ] ; then
        sudo mkdir -p $ES_VOLUME
        sudo chown 1000:1000 $ES_VOLUME
    fi
    # allow es and es-ops to mount volumes from the host
    os::cmd::expect_success "oadm policy add-scc-to-user hostmount-anyuid \
         system:serviceaccount:logging:aggregated-logging-elasticsearch"
    # get es dc
    esdc=`oc get dc -l component=es -o jsonpath='{.items[0].metadata.name}'`
    # shutdown es
    espod=`get_running_pod es`
    os::cmd::expect_success "oc scale dc $esdc --replicas=0"
    os::cmd::try_until_failure "oc describe pod $espod > /dev/null" "$(( 3 * TIME_MIN ))"
    # mount volume manually on ordinary cluster
    os::cmd::expect_success "oc volume dc/$esdc \
                             --add --overwrite --name=elasticsearch-storage \
                             --type=hostPath --path=$ES_VOLUME"
    # start up es
    os::cmd::try_until_text "oc deploy $esdc --latest" "Started" "$(( 3 * TIME_MIN ))"
    os::cmd::expect_success "oc scale dc $esdc --replicas=1"
    os::cmd::try_until_text "oc get pods -l component=es" "Running" "$(( 3 * TIME_MIN ))"
fi

# start fluentd
os::cmd::try_until_success "oc get daemonset logging-fluentd" "$(( 1 * TIME_MIN ))"
os::cmd::expect_success "oc label node --all logging-infra-fluentd=true"

# the old way with dc's
# # scale up a fluentd pod
# os::cmd::try_until_success "oc get dc logging-fluentd"
# os::cmd::expect_success "oc scale dc logging-fluentd --replicas=1"

os::cmd::try_until_text "oc get pods -l component=fluentd" "Running" "$(( 5 * TIME_MIN ))"
### logging component pods are now created and deployed ###

### add the test app ###
# copied from end-to-end/core.sh
function wait_for_app() {
  echo "[INFO] Waiting for app in namespace $1"
  echo "[INFO] Waiting for database pod to start"
  os::cmd::try_until_text "oc get -n $1 pods -l name=database" 'Running'

  echo "[INFO] Waiting for database service to start"
  os::cmd::try_until_text "oc get -n $1 services" 'database' "$(( 2 * TIME_MIN ))"
  DB_IP=$(oc get -n $1 --output-version=v1beta3 --template="{{ .spec.portalIP }}" service database)

  echo "[INFO] Waiting for frontend pod to start"
  os::cmd::try_until_text "oc get -n $1 pods" 'frontend.+Running' "$(( 2 * TIME_MIN ))"

  echo "[INFO] Waiting for frontend service to start"
  os::cmd::try_until_text "oc get -n $1 services" 'frontend' "$(( 2 * TIME_MIN ))"
  FRONTEND_IP=$(oc get -n $1 --output-version=v1beta3 --template="{{ .spec.portalIP }}" service frontend)

  echo "[INFO] Waiting for database to start..."
  wait_for_url_timed "http://${DB_IP}:5434" "[INFO] Database says: " $((3*TIME_MIN))

  echo "[INFO] Waiting for app to start..."
  wait_for_url_timed "http://${FRONTEND_IP}:5432" "[INFO] Frontend says: " $((2*TIME_MIN))

  echo "[INFO] Testing app"
  wait_for_command '[[ "$(curl -s -X POST http://${FRONTEND_IP}:5432/keys/foo -d value=1337)" = "Key created" ]]'
  wait_for_command '[[ "$(curl -s http://${FRONTEND_IP}:5432/keys/foo)" = "1337" ]]'
}

os::cmd::expect_success "$OS_ROOT/examples/sample-app/pullimages.sh"
os::cmd::expect_success "oc new-project test --display-name='example app for logging testing' --description='This is an example app for logging testing'"
os::cmd::expect_success "oc new-app -f $OS_ROOT/examples/sample-app/application-template-stibuild.json"
os::build:wait_for_start "test"
os::build:wait_for_end "test"
wait_for_app "test"
### test app added ###

### run logging tests ###
os::cmd::expect_success "oc login -u 'system:admin'"
os::cmd::expect_success "oc project logging"
pushd $OS_O_A_L_DIR/hack/testing
if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
    USE_CLUSTER=true
else
    USE_CLUSTER=
fi

if [ "$TEST_PERF" = "true" ] ; then
    echo "Running performance tests"
    for test in perf-*.sh ; do
        if [ -x ./$test ] ; then
            ./$test $USE_CLUSTER
        fi
    done
else
    echo "Running e2e tests"
    # e2e-test runs checks which do not modify any data - safe to use
    # in production environments
    ./e2e-test.sh $USE_CLUSTER
    # test-* tests modify data and are not generally safe to use
    # in production environments
    for test in test-*.sh ; do
        if [ -x ./$test ] ; then
            ./$test $USE_CLUSTER
        fi
    done
fi

function reinstall() {
  echo "running with reinstall mode"

  os::cmd::expect_success "oc new-app \
                        logging-deployer-template \
                        -p ENABLE_OPS_CLUSTER=$ENABLE_OPS_CLUSTER \
                        ${pvc_params} \
                        -p IMAGE_PREFIX=$imageprefix \
                        -p KIBANA_HOSTNAME=kibana.example.com \
                        -p ES_CLUSTER_SIZE=1 \
                        -p PUBLIC_MASTER_URL=https://localhost:8443${masterurlhack} \
                        -p MODE=reinstall"

  REINSTALL_POD=$(get_latest_pod "logging-infra=deployer")

  # Giving the upgrade process a bit more time to run to completion... failed last time at 10 minutes
  os::cmd::try_until_text "oc get pods $REINSTALL_POD" "Completed" "$(( 5 * TIME_MIN ))"

  os::cmd::try_until_text "oc get pods -l component=es" "Running" "$(( 3 * TIME_MIN ))"
  os::cmd::try_until_text "oc get pods -l component=kibana" "Running" "$(( 3 * TIME_MIN ))"
  os::cmd::try_until_text "oc get pods -l component=curator" "Running" "$(( 3 * TIME_MIN ))"
  os::cmd::try_until_text "oc get pods -l component=fluentd" "Running" "$(( 3 * TIME_MIN ))"
}

TEST_DIVIDER="------------------------------------------"

echo $TEST_DIVIDER
reinstall
./e2e-test.sh $USE_CLUSTER

popd
### finished logging tests ###

### END ###

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

# includes util.sh and text.sh
source "${OS_ROOT}/hack/cmd_util.sh"
source "${OS_ROOT}/hack/common.sh"
source "${OS_ROOT}/hack/lib/log.sh"
os::log::install_errexit

source "${OS_ROOT}/hack/lib/util/environment.sh"
os::util::environment::setup_time_vars

cd "${OS_ROOT}"

os::build::setup_env

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

    if [ "$DEBUG_FAILURES" = "true" ] ; then
        echo debug failures
        sleep 54321 || echo debugging done - continuing
    fi
    cleanup_openshift
    echo "[INFO] Exiting at " `date`
    ENDTIME=$(date +%s); echo "$0 took $(($ENDTIME - $STARTTIME)) seconds"
    exit $out
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
                oc start-build $bc
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

configure_os_server
start_os_server

export KUBECONFIG="${ADMIN_KUBECONFIG}"

install_registry
wait_for_registry

######### logging specific code starts here ####################

### create and deploy the logging component pods ###
masterurlhack=",MASTER_URL=https://172.30.0.1:443"
OS_O_A_L_DIR=${OS_O_A_L_DIR:-$OS_ROOT/test/extended/origin-aggregated-logging}
os::cmd::expect_success "oc new-project logging"
os::cmd::expect_success "oc secrets new logging-deployer nothing=/dev/null"
os::cmd::expect_success "echo 'apiVersion: v1
kind: ServiceAccount
metadata:
  name: logging-deployer
secrets:
- name: logging-deployer
' | oc create -f -"
os::cmd::expect_success "oc policy add-role-to-user edit system:serviceaccount:logging:logging-deployer"
if [ -n "$USE_LOGGING_DEPLOYER" ] ; then
    imageprefix="docker.io/openshift/origin-"
elif [ -n "$USE_LOGGING_DEPLOYER_SCRIPT" ] ; then
    pushd $OS_O_A_L_DIR/deployment
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
                if [ "$bc" = "logging-auth-proxy" ] ; then
                    oc start-build $bc
                else
                    oc start-build --from-repo $OS_O_A_L_DIR $bc
                fi
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

# # old way
# log_priv_user=$(create_valid_file add-hostmount-anyuid-logging-user.yml)
# os::cmd::expect_success "oc get scc/hostmount-anyuid -o yaml > $log_priv_user"
# os::cmd::expect_success "echo '- system:serviceaccount:logging:aggregated-logging-fluentd' >> $log_priv_user"
# os::cmd::expect_success "oc replace -f $log_priv_user"
os::cmd::expect_success "oadm policy add-scc-to-user hostmount-anyuid system:serviceaccount:logging:aggregated-logging-fluentd"
sleep 5
os::cmd::expect_success "oadm policy add-cluster-role-to-user cluster-reader \
                      system:serviceaccount:logging:aggregated-logging-fluentd"
sleep 5
if [ ! -n "$USE_LOGGING_DEPLOYER_SCRIPT" ] ; then
    os::cmd::expect_success "oc process \
                          -f $OS_O_A_L_DIR/deployment/deployer.yaml \
                          -v ENABLE_OPS_CLUSTER=$ENABLE_OPS_CLUSTER,IMAGE_PREFIX=$imageprefix,KIBANA_HOSTNAME=kibana.example.com,ES_CLUSTER_SIZE=1,PUBLIC_MASTER_URL=https://localhost:8443${masterurlhack} \
                          | oc create -f -"
    os::cmd::try_until_text "oc describe bc logging-deployment | awk '/^logging-deployment-/ {print \$2}'" "complete"
    os::cmd::try_until_text "oc get pods -l component=deployer" "Completed" "$(( 3 * TIME_MIN ))"
fi
# see if expected pods are running
os::cmd::try_until_text "oc get pods -l component=es" "Running" "$(( 3 * TIME_MIN ))"
os::cmd::try_until_text "oc get pods -l component=kibana" "Running" "$(( 3 * TIME_MIN ))"
os::cmd::try_until_text "oc get pods -l component=curator" "Running" "$(( 3 * TIME_MIN ))"
if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
    os::cmd::try_until_text "oc get pods -l component=es-ops" "Running" "$(( 3 * TIME_MIN ))"
    os::cmd::try_until_text "oc get pods -l component=kibana-ops" "Running" "$(( 3 * TIME_MIN ))"
    os::cmd::try_until_text "oc get pods -l component=curator-ops" "Running" "$(( 3 * TIME_MIN ))"
fi

# this fails because the imagestreams already exist
os::cmd::expect_failure_and_text "oc process logging-support-template | oc create -f -" "already exists"

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

### run logging e2e tests ###
os::cmd::expect_success "oc login -u 'system:admin'"
os::cmd::expect_success "oc project logging"
pushd $OS_O_A_L_DIR/hack/testing
if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
    USE_CLUSTER=true
else
    USE_CLUSTER=
fi
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
popd
### finished logging e2e tests ###

### END ###

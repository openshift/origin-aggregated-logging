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
OS_ROOT=${OS_ROOT:-$(dirname "${BASH_SOURCE}")/../../../origin}
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
DO_CLEANUP=${DO_CLEANUP:-true}
USE_LOCAL_SOURCE=${USE_LOCAL_SOURCE:-false}
TEST_PERF=${TEST_PERF:-false}
ES_VOLUME=${ES_VOLUME:-/var/lib/es}
ES_OPS_VOLUME=${ES_OPS_VOLUME:-/var/lib/es-ops}
NOSETUP=
if [ "${1:-}" = NOSETUP ] ; then
    NOSETUP=1
fi

# have to do this after all argument processing, otherwise,
# scripts that we use via source or `.` will inherit the args!
set --

# if USE_JOURNAL is empty, fluentd will use whatever docker is using
if [ "${USE_JOURNAL:-}" = false ] ; then
    # see if docker is using the journal log driver - if so, change it to json-file
    if grep -q -- '--log-driver=journald' /etc/sysconfig/docker ; then
        sudo sed -i.bak 's/--log-driver=journald/--log-driver=json-file/' /etc/sysconfig/docker
        sudo systemctl restart docker
    fi
elif [ "${USE_JOURNAL:-}" = true ] ; then
    # see if docker is explicitly configured to use the json-file log driver
    if grep -q -- '--log-driver=json-file' /etc/sysconfig/docker ; then
        sudo sed -i.bak 's/--log-driver=json-file/--log-driver=journald/' /etc/sysconfig/docker
        sudo systemctl restart docker
    elif grep -q '^OPTIONS=' /etc/sysconfig/docker ; then
        # using default log driver - make it explicit to use journald
        sudo sed -i.bak "/^OPTIONS=/ s/'$/ --log-driver=journald'/" /etc/sysconfig/docker
        sudo systemctl restart docker
    else
        # using default log driver - make it explicit to use journald
        sudo cp /etc/sysconfig/docker /etc/sysconfig/docker.bak
        echo "OPTIONS=--log-driver=journald" | sudo tee -a /etc/sysconfig/docker
        sudo systemctl restart docker
    fi
fi

# use a few tools from the deployer
source "$OS_O_A_L_DIR/deployer/scripts/util.sh"

# include all the origin test libs we need
if [ -f ${OS_ROOT}/hack/lib/init.sh ] ; then
    source ${OS_ROOT}/hack/lib/init.sh # one stop shopping
else
    for lib in "${OS_ROOT}"/hack/{util.sh,text.sh} \
               "${OS_ROOT}"/hack/lib/*.sh "${OS_ROOT}"/hack/lib/**/*.sh
    do source "$lib"; done
fi
os::log::stacktrace::install
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
        echo debug failures - when you are finished, 'ps -ef|grep 987654' then kill that sleep process
        sleep 987654 || echo debugging done - continuing
    fi
    if [ "$DO_CLEANUP" = "true" ] ; then
        cleanup_openshift
    fi
    echo "[INFO] Exiting at " `date`
    ENDTIME=$(date +%s); echo "$0 took $(($ENDTIME - $STARTTIME)) seconds"
    return $out
}

trap "exit" INT TERM
trap "cleanup" EXIT

echo "[INFO] Starting logging tests at " `date`

os::util::ensure::iptables_privileges_exist
# override LOG_DIR and ARTIFACTS_DIR
export LOG_DIR=${LOG_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging/logs}
export ARTIFACT_DIR=${ARTIFACT_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging/artifacts}
os::util::environment::use_sudo
os::util::environment::setup_all_server_vars "origin-aggregated-logging/"

os::log::system::start

export KUBELET_HOST=$(hostname)

if [ $NOSETUP = 1 ] ; then
    echo skipping openshift setup and start
else
    os::start::configure_server
    if [ -n "${KIBANA_HOST:-}" ] ; then
        # add loggingPublicURL so the OpenShift UI Console will include a link for Kibana
        # this part stolen from util.sh configure_os_server()
        cp ${SERVER_CONFIG_DIR}/master/master-config.yaml ${SERVER_CONFIG_DIR}/master/master-config.orig.yaml
        openshift ex config patch ${SERVER_CONFIG_DIR}/master/master-config.orig.yaml \
                  --patch="{\"assetConfig\": {\"loggingPublicURL\": \"https://${KIBANA_HOST}\"}}" > \
                  ${SERVER_CONFIG_DIR}/master/master-config.yaml
    fi
    os::start::server
fi

export KUBECONFIG="${ADMIN_KUBECONFIG:-$MASTER_CONFIG_DIR/admin.kubeconfig}"
if [ ! -f $KUBECONFIG ] ; then
    if [ -d /etc/origin ] ; then
        SERVER_CONFIG_DIR=/etc/origin
        MASTER_CONFIG_DIR=$SERVER_CONFIG_DIR/master
        NODE_CONFIG_DIR=$SERVER_CONFIG_DIR/node-$KUBELET_HOST
        KUBECONFIG=$MASTER_CONFIG_DIR/admin.kubeconfig
    else
        echo ERROR: cannot find admin.kubeconfig
        exit 1
    fi
fi

if [ $NOSETUP = 1 ] ; then
    echo skipping registry setup and start
else
    os::start::registry
    oc rollout status dc/docker-registry
fi

######### logging specific code starts here ####################

configure_es_with_hostpath() {
    local es_dc=`oc get dc -l component=$1 -o jsonpath='{.items[0].metadata.name}'`
    if oc set volume dc $es_dc | grep -q "empty directory as elasticsearch-storage" ; then
        echo setting up $1 with persistent storage
    else
        return 0
    fi
    sudo setenforce Permissive # doesn't work with Enforcing
    # type=AVC msg=audit(1493060981.565:2610): avc:  denied  { write } for  pid=58448 comm="java" name="logging-es" dev="vda1" ino=2560575 scontext=system_u:system_r:svirt_lxc_net_t:s0:c4,c7 tcontext=unconfined_u:object_r:var_lib_t:s0 tclass=dir
    local espod=`get_running_pod $1`
    os::cmd::expect_success "oc scale dc $es_dc --replicas=0"
    os::cmd::try_until_failure "oc describe pod $espod > /dev/null" "$(( 3 * TIME_MIN ))"
    # allow es to mount volumes from the host
    oadm policy add-scc-to-user hostmount-anyuid \
         system:serviceaccount:logging:aggregated-logging-elasticsearch
    if [ ! -d $2 ] ; then
        sudo mkdir -p $2
        sudo chown 1000:1000 $2
    fi
    oc volume dc/$es_dc --add --overwrite --name=elasticsearch-storage \
       --type=hostPath --path=$2
    oc rollout latest $es_dc
    os::cmd::expect_success "oc scale dc $es_dc --replicas=1"
    os::cmd::try_until_text "oc get pods -l component=$1" "Running" "$(( 3 * TIME_MIN ))"
}

configure_all_es_with_hostpath() {
    # es and es-ops need persistent storage
    configure_es_with_hostpath es $ES_VOLUME
    if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
        configure_es_with_hostpath es-ops $ES_OPS_VOLUME
    fi
}

if [ $NOSETUP = 1 ] ; then
    oc project logging > /dev/null
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
       -v LOGGING_FORK_URL=$GIT_URL -v LOGGING_FORK_BRANCH=$GIT_BRANCH \
       | build_filter | oc create -f -"
    post_build
    os::cmd::expect_success "wait_for_builds_complete"
    imageprefix=`oc get is | awk '$1 == "logging-deployment" {print gensub(/^([^/]*\/logging\/).*$/, "\\\1", 1, $2)}'`
    sleep 5
    # set up es and es-ops to use a PV local disk
    configure_all_es_with_hostpath
else
    source $OS_O_A_L_DIR/hack/testing/setup-and-deploy-logging
fi

### add the test app ###
# copied from end-to-end/core.sh
function wait_for_app() {
  echo "[INFO] Waiting for app in namespace $1"
  echo "[INFO] Waiting for database pod to start"
  os::cmd::try_until_text "oc get -n $1 pods -l name=database" 'Running' "$(( 5 * TIME_MIN ))"

  echo "[INFO] Waiting for database service to start"
  os::cmd::try_until_text "oc get -n $1 services" 'database' "$(( 5 * TIME_MIN ))"
  DB_IP=$(oc get -n $1 --output-version=v1beta3 --template="{{ .spec.clusterIP }}" service database)

  echo "[INFO] Waiting for frontend pod to start"
  os::cmd::try_until_text "oc get -n $1 pods" 'frontend.+Running' "$(( 5 * TIME_MIN ))"

  echo "[INFO] Waiting for frontend service to start"
  os::cmd::try_until_text "oc get -n $1 services" 'frontend' "$(( 5 * TIME_MIN ))"
  FRONTEND_IP=$(oc get -n $1 --output-version=v1beta3 --template="{{ .spec.clusterIP }}" service frontend)

  echo "[INFO] Waiting for database to start..."
  os::cmd::try_until_success "curl --max-time 2 --fail --silent 'http://${DB_IP}:5434'" $((5*TIME_MIN))

  echo "[INFO] Waiting for app to start..."
  os::cmd::try_until_success "curl --max-time 2 --fail --silent 'http://${FRONTEND_IP}:5432'" $((5*TIME_MIN))

  echo "[INFO] Testing app"
  os::cmd::try_until_text "curl -s -X POST http://${FRONTEND_IP}:5432/keys/foo -d value=1337" "Key created" "$((60*TIME_SEC))"
  os::cmd::try_until_text "curl -s http://${FRONTEND_IP}:5432/keys/foo" "1337" "$((60*TIME_SEC))"
}

os::cmd::expect_success "$OS_ROOT/examples/sample-app/pullimages.sh"
os::cmd::expect_success "oc new-project test --display-name='example app for logging testing' --description='This is an example app for logging testing'"
os::cmd::expect_success "oc new-app -f $OS_ROOT/examples/sample-app/application-template-stibuild.json"
os::cmd::try_until_text "oc get builds --namespace test -o jsonpath='{.items[0].status.phase}'" "Running" "$(( 10*TIME_MIN ))"
os::cmd::try_until_text "oc get builds --namespace test -o jsonpath='{.items[0].status.phase}'" "Complete" "$(( 10*TIME_MIN ))"
wait_for_app "test"
### test app added ###

### kibana setup - router account, router, kibana user ###
oc get serviceaccount -n default router || os::cmd::expect_success "oc create serviceaccount router -n default"
os::cmd::expect_success "oadm policy add-scc-to-user privileged system:serviceaccount:default:router"
os::cmd::expect_success "oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:default:router"
rtr=`oc get -n default pods -l router=router -o name 2> /dev/null`
if [ -z "$rtr" ] ; then
    os::cmd::expect_success "oadm router --create --namespace default --service-account=router \
                             --credentials $MASTER_CONFIG_DIR/openshift-router.kubeconfig"
fi
os::cmd::expect_success "oc login --username=kibtest --password=kibtest"
os::cmd::expect_success "oc login --username=system:admin"
os::cmd::expect_success "oadm policy add-cluster-role-to-user cluster-admin kibtest"
os::cmd::expect_success "oc project logging"
# also give kibtest access to cluster stats
espod=`get_running_pod es`
wait_for_es_ready $espod 30
oc exec $espod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
   --key /etc/elasticsearch/secret/admin-key \
   https://localhost:9200/.searchguard.$espod/rolesmapping/0 | \
    python -c 'import json, sys; hsh = json.loads(sys.stdin.read())["_source"]; hsh["sg_role_admin"]["users"].append("kibtest"); print json.dumps(hsh)' | \
    oc exec -i $espod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
       --key /etc/elasticsearch/secret/admin-key \
       https://localhost:9200/.searchguard.$espod/rolesmapping/0 -XPUT -d@- | \
    python -mjson.tool
if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
    esopspod=`get_running_pod es-ops`
    wait_for_es_ready $esopspod 30
    oc exec $esopspod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
       --key /etc/elasticsearch/secret/admin-key \
       https://localhost:9200/.searchguard.$esopspod/rolesmapping/0 | \
        python -c 'import json, sys; hsh = json.loads(sys.stdin.read())["_source"]; hsh["sg_role_admin"]["users"].append("kibtest"); print json.dumps(hsh)' | \
        oc exec -i $esopspod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
           --key /etc/elasticsearch/secret/admin-key \
           https://localhost:9200/.searchguard.$esopspod/rolesmapping/0 -XPUT -d@- | \
        python -mjson.tool
fi

# verify that kibtest user has access to cluster stats
sleep 5
oc login --username=kibtest --password=kibtest
test_token="$(oc whoami -t)"
test_name="$(oc whoami)"
test_ip="127.0.0.1"
oc login --username=system:admin
oc project logging
kibpod=`get_running_pod kibana`
status=$(oc exec $kibpod -c kibana -- curl --connect-timeout 1 -s -k \
   --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
   -H "X-Proxy-Remote-User: $test_name" -H "Authorization: Bearer $test_token" -H "X-Forwarded-For: 127.0.0.1" \
   https://logging-es:9200/_cluster/health -o /dev/null -w '%{response_code}')
os::cmd::expect_success "test $status = 200"
if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
    kibpod=`get_running_pod kibana-ops`
    status=$(oc exec $kibpod -c kibana -- curl --connect-timeout 1 -s -k \
       --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
       -H "X-Proxy-Remote-User: $test_name" -H "Authorization: Bearer $test_token" -H "X-Forwarded-For: 127.0.0.1" \
       https://logging-es-ops:9200/_cluster/health -o /dev/null -w '%{response_code}')
    os::cmd::expect_success "test $status = 200"
fi

# external elasticsearch access - reencrypt route - need certs, keys
if [ -n "${ES_HOST:-}" -o -n "${ES_OPS_HOST:-}" ] ; then
    destca=`mktemp`
    # this is the same ca that issued the es server cert
    oc get secret logging-elasticsearch \
       --template='{{index .data "admin-ca"}}' | base64 -d > $destca
    if [ -n "${ES_HOST:-}" ] ; then
        openshift admin ca create-server-cert --key=$ARTIFACT_DIR/es.key \
                  --cert=$ARTIFACT_DIR/es.crt --hostnames=$ES_HOST \
                  --signer-cert=$MASTER_CONFIG_DIR/ca.crt \
                  --signer-key=$MASTER_CONFIG_DIR/ca.key \
                  --signer-serial=$MASTER_CONFIG_DIR/ca.serial.txt
        oc create route reencrypt --service logging-es --port 9200 \
                  --hostname $ES_HOST --dest-ca-cert $destca \
                  --ca-cert $MASTER_CONFIG_DIR/ca.crt \
                  --cert $ARTIFACT_DIR/es.crt \
                  --key $ARTIFACT_DIR/es.key
    fi
    if [ -n "${ES_OPS_HOST:-}" ] ; then
        openshift admin ca create-server-cert --key=$ARTIFACT_DIR/es-ops.key \
                  --cert=$ARTIFACT_DIR/es-ops.crt --hostnames=$ES_OPS_HOST \
                  --signer-cert=$MASTER_CONFIG_DIR/ca.crt \
                  --signer-key=$MASTER_CONFIG_DIR/ca.key \
                  --signer-serial=$MASTER_CONFIG_DIR/ca.serial.txt
        oc create route reencrypt --service logging-es-ops --port 9200 \
                  --hostname $ES_OPS_HOST --dest-ca-cert $destca \
                  --ca-cert $MASTER_CONFIG_DIR/ca.crt \
                  --cert $ARTIFACT_DIR/es-ops.crt \
                  --key $ARTIFACT_DIR/es-ops.key
    fi
    rm -f $destca
fi

if [ "${SETUP_ONLY:-}" = "true" ] ; then
    exit 0
fi

### run logging tests ###
os::cmd::expect_success "oc project logging"
pushd $OS_O_A_L_DIR/hack/testing
if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
    USE_CLUSTER=true
else
    USE_CLUSTER=
fi

# when fluentd starts up it may take a while before it catches up with all of the logs
# let's wait until that happens
wait_for_fluentd_to_catch_up

if [ "$TEST_PERF" = "true" ] ; then
    echo "Running performance tests"
    for test in perf-*.sh ; do
        if [ -x ./$test ] ; then
            (. ./$test $USE_CLUSTER)
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
            echo running test $test
            (. ./$test $USE_CLUSTER)
        fi
    done
fi

function reinstall() {
  echo "running with reinstall mode"

  os::cmd::expect_success "oc new-app \
                        logging-deployer-template \
                        -p IMAGE_PREFIX=$imageprefix \
                        ${masterurlhack} ${pvc_params} \
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

os::cmd::try_until_text "oc get dc -o name -l component=es-ops" "ops"
ops_dc=$(oc get dc -o name -l component=es-ops) || exit 1
os::cmd::expect_success "oc patch $ops_dc \
   -p '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"elasticsearch\",\"securityContext\":{\"privileged\": true}}]}}}}'"
barename=`echo $ops_dc|sed 's,deploymentconfig/,,'`

# first cancel any current deployments
deploy_num=`oc deploy $ops_dc --cancel=true | awk -F'[ #]+' '/^Cancelled deployment/ {print $3}'`
if [ -n "${deploy_num}" ]; then
  echo "Cancelling deployment ${deploy_num} for ${ops_dc}"
  os::cmd::try_until_failure "oc describe pod/${barename}-${deploy_num}-deploy > /dev/null" "$(( 3 * TIME_MIN ))"
else
  echo No currently running deployments...
fi

# get the deployment number
deploynum=`oc deploy $ops_dc --latest | awk -F'[ #]+' '/^Started deployment/ {print $3}'`
if [ -z "${deploynum:-}" ] ; then
    echo Error attempting to deploy $ops_dc
    exit 1
fi
# look for a deployment with the given deployment number
os::cmd::try_until_text "oc get pods -l deployment=${barename}-${deploynum}" "Running"  "$(( 3 * TIME_MIN ))"

./e2e-test.sh $USE_CLUSTER

popd
### finished logging tests ###

### END ###

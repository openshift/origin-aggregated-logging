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
DO_CLEANUP=${DO_CLEANUP:-true}
USE_LOCAL_SOURCE=${USE_LOCAL_SOURCE:-false}
TEST_PERF=${TEST_PERF:-false}
ES_VOLUME=${ES_VOLUME:-/var/lib/es}
ES_OPS_VOLUME=${ES_OPS_VOLUME:-/var/lib/es-ops}

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

export KUBECONFIG="${ADMIN_KUBECONFIG}"

os::start::registry
oc rollout status dc/docker-registry

######### logging specific code starts here ####################

### create and deploy the logging component pods ###
masterurlhack="-p MASTER_URL=https://172.30.0.1:443"
OS_O_A_L_DIR=${OS_O_A_L_DIR:-$OS_ROOT/test/extended/origin-aggregated-logging}
os::cmd::expect_success "oadm new-project logging --node-selector=''"
os::cmd::expect_success "oc project logging"
os::cmd::expect_success "oc create -f $OS_O_A_L_DIR/deployer/deployer.yaml"
os::cmd::expect_success "oc new-app logging-deployer-account-template"
os::cmd::expect_success "oadm policy add-cluster-role-to-user oauth-editor system:serviceaccount:logging:logging-deployer"
deployer_args="--from-literal enable-ops-cluster=${ENABLE_OPS_CLUSTER} \
    --from-literal use-journal=${USE_JOURNAL:-} \
    --from-literal journal-source=${JOURNAL_SOURCE:-} \
    --from-literal journal-read-from-head=${JOURNAL_READ_FROM_HEAD:-false}"
if [ -n "${PUBLIC_MASTER_HOST:-}" ] ; then
    deployer_args="$deployer_args --from-literal public-master-url=https://${PUBLIC_MASTER_HOST}:8443"
fi
if [ -n "${KIBANA_HOST:-}" ] ; then
    deployer_args="$deployer_args --from-literal kibana-hostname=$KIBANA_HOST"
    if getent hosts $KIBANA_HOST > /dev/null 2>&1 ; then
        echo kibana host $KIBANA_HOST is `getent hosts $KIBANA_HOST` `getent ahostsv4 $KIBANA_HOST`
    else
        # does not resolve - add it as an alias for the external IP
        ip=`getent hosts $PUBLIC_MASTER_HOST | awk '{print $1}'`
        if grep -q \^$ip /etc/hosts ; then
            sudo sed -i -e 's/^\('$ip'.*\)$/\1 '$KIBANA_HOST'/' /etc/hosts
        else
            echo $ip $KIBANA_HOST | sudo tee -a /etc/hosts
        fi
    fi
    # generate externally facing cert for router
    openshift admin ca create-server-cert --key=$ARTIFACT_DIR/kibana.key \
          --cert=$ARTIFACT_DIR/kibana.crt --hostnames=$KIBANA_HOST \
          --signer-cert=$MASTER_CONFIG_DIR/ca.crt \
          --signer-key=$MASTER_CONFIG_DIR/ca.key \
          --signer-serial=$MASTER_CONFIG_DIR/ca.serial.txt
    deployer_args="$deployer_args \
                   --from-file=kibana.crt=$ARTIFACT_DIR/kibana.crt \
                   --from-file=kibana.key=$ARTIFACT_DIR/kibana.key \
                   --from-file=kibana.ca.crt=$MASTER_CONFIG_DIR/ca.crt"
fi
if [ -n "${KIBANA_OPS_HOST:-}" ] ; then
    deployer_args="$deployer_args --from-literal kibana-ops-hostname=$KIBANA_OPS_HOST"
    if getent hosts $KIBANA_OPS_HOST > /dev/null 2>&1 ; then
        echo kibana host $KIBANA_OPS_HOST is `getent hosts $KIBANA_OPS_HOST` `getent ahostsv4 $KIBANA_OPS_HOST`
    else
        # does not resolve - add it as an alias for the external IP
        ip=`getent hosts $PUBLIC_MASTER_HOST | awk '{print $1}'`
        if grep -q \^$ip /etc/hosts ; then
            sudo sed -i -e 's/^\('$ip'.*\)$/\1 '$KIBANA_OPS_HOST'/' /etc/hosts
        else
            echo $ip $KIBANA_OPS_HOST | sudo tee -a /etc/hosts
        fi
    fi
    # generate externally facing cert for router
    openshift admin ca create-server-cert --key=$ARTIFACT_DIR/kibana-ops.key \
          --cert=$ARTIFACT_DIR/kibana-ops.crt --hostnames=$KIBANA_OPS_HOST \
          --signer-cert=$MASTER_CONFIG_DIR/ca.crt \
          --signer-key=$MASTER_CONFIG_DIR/ca.key \
          --signer-serial=$MASTER_CONFIG_DIR/ca.serial.txt
    deployer_args="$deployer_args \
                   --from-file=kibana-ops.crt=$ARTIFACT_DIR/kibana-ops.crt \
                   --from-file=kibana-ops.key=$ARTIFACT_DIR/kibana-ops.key \
                   --from-file=kibana-ops.ca.crt=$MASTER_CONFIG_DIR/ca.crt"
fi
os::cmd::expect_success "oc create configmap logging-deployer $deployer_args"

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
       -v LOGGING_FORK_URL=$GIT_URL -v LOGGING_FORK_BRANCH=$GIT_BRANCH \
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
    os::cmd::expect_success "oc process -f $OS_O_A_L_DIR/hack/templates/pv-hostmount.yaml -v SIZE=10 -v PATH=${ES_OPS_VOLUME} | oc create -f -"
    pvc_params="-p ES_OPS_PVC_SIZE=10 -p ES_OPS_PVC_PREFIX=es-ops-pvc-" # deployer will create PVC
fi
# TODO: put this back to hostmount-anyuid once we've resolved the SELinux problem with that
# https://github.com/openshift/origin-aggregated-logging/issues/89
os::cmd::expect_success "oadm policy add-scc-to-user privileged system:serviceaccount:logging:aggregated-logging-fluentd"
sleep 5
os::cmd::expect_success "oadm policy add-cluster-role-to-user cluster-reader \
                      system:serviceaccount:logging:aggregated-logging-fluentd"
sleep 5
os::cmd::expect_success "oadm policy add-cluster-role-to-user rolebinding-reader \
                      system:serviceaccount:logging:aggregated-logging-elasticsearch"
sleep 5
if [ ! -n "$USE_LOGGING_DEPLOYER_SCRIPT" ] ; then
    os::cmd::expect_success "oc new-app \
                          logging-deployer-template \
                          -p IMAGE_PREFIX=$imageprefix \
                          ${pvc_params} ${masterurlhack}"

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

### kibana setup - router account, router, kibana user ###
os::cmd::expect_success "oc create serviceaccount router -n default"
os::cmd::expect_success "oadm policy add-scc-to-user privileged system:serviceaccount:default:router"
os::cmd::expect_success "oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:default:router"
os::cmd::expect_success "oadm router --create --namespace default --service-account=router \
     --credentials $MASTER_CONFIG_DIR/openshift-router.kubeconfig"
os::cmd::expect_success "oc login --username=kibtest --password=kibtest"
os::cmd::expect_success "oc login --username=system:admin"
os::cmd::expect_success "oadm policy add-cluster-role-to-user cluster-admin kibtest"
os::cmd::expect_success "oc project logging"
# also give kibtest access to cluster stats
espod=`get_running_pod es`
wait_for_es_ready $espod 30
oc exec $espod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
   --key /etc/elasticsearch/secret/admin-key \
   https://logging-es:9200/.searchguard.$espod/rolesmapping/0 | \
    python -c 'import json, sys; hsh = json.loads(sys.stdin.read())["_source"]; hsh["sg_role_admin"]["users"].append("kibtest"); print json.dumps(hsh)' | \
    oc exec -i $espod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
       --key /etc/elasticsearch/secret/admin-key \
       https://logging-es:9200/.searchguard.$espod/rolesmapping/0 -XPUT -d@- | \
    python -mjson.tool
if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
    esopspod=`get_running_pod es-ops`
    wait_for_es_ready $esopspod 30
    oc exec $esopspod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
       --key /etc/elasticsearch/secret/admin-key \
       https://logging-es-ops:9200/.searchguard.$esopspod/rolesmapping/0 | \
        python -c 'import json, sys; hsh = json.loads(sys.stdin.read())["_source"]; hsh["sg_role_admin"]["users"].append("kibtest"); print json.dumps(hsh)' | \
        oc exec -i $esopspod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
           --key /etc/elasticsearch/secret/admin-key \
           https://logging-es-ops:9200/.searchguard.$esopspod/rolesmapping/0 -XPUT -d@- | \
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

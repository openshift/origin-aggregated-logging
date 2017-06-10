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
export OS_O_A_L_DIR
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
export MUX_ALLOW_EXTERNAL=${MUX_ALLOW_EXTERNAL:-false}
export USE_MUX_CLIENT=${USE_MUX_CLIENT:-false}
export USE_MUX=${USE_MUX:-false}
if [ "$MUX_ALLOW_EXTERNAL" = true -o "$USE_MUX_CLIENT" = true ] ; then
    export USE_MUX=true
fi
NOSETUP=
if [ "${1:-}" = NOSETUP ] ; then
    NOSETUP=1
fi
# have to do this after all argument processing, otherwise,
# scripts that we use via source or `.` will inherit the args!
set --

# use a few tools from the deployer
source "$OS_O_A_L_DIR/deployer/scripts/util.sh"

# if USE_JOURNAL is empty, fluentd will use whatever docker is using
if [ "${USE_JOURNAL:-}" = false ] && docker_uses_journal ; then
    # see if docker is using the journal log driver - if so, change it to json-file
    if [ -f /etc/docker/daemon.json ] ; then
        sudo sed -i.bak 's/"log-driver":.*"..*"/"log-driver": "json-file"/' /etc/docker/daemon.json
    fi
    if [ -f /etc/sysconfig/docker ] ; then
        sudo sed -i.bak 's/--log-driver=journald/--log-driver=json-file/' /etc/sysconfig/docker
    fi
    sudo systemctl restart docker
elif [ "${USE_JOURNAL:-}" = true ] && ! docker_uses_journal ; then
    # see if docker is explicitly configured to use the json-file log driver
    if grep -q '^[^#].*"log-driver":.*json-file' /etc/docker/daemon.json 2> /dev/null ; then
        sudo sed -i.bak 's/^[^#].*"log-driver":.*"..*"/  "log-driver": "journald"/' /etc/docker/daemon.json
        sudo systemctl restart docker
    elif [ -f /etc/docker/daemon.json ] ; then
        sudo cat /etc/docker/daemon.json | python -c '
import json, sys
hsh = json.loads(sys.stdin.read())
hsh["log-driver"] = "journald"
json.dumps(hsh,indent=2)
' | sudo tee /etc/docker/daemon.json.new
        sudo mv /etc/docker/daemon.json.new /etc/docker/daemon.json
      sudo systemctl restart docker
    fi
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

# have to set these here so setup_tmpdir_vars will not give them bogus values
export LOG_DIR=${LOG_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging/logs}
export ARTIFACT_DIR=${ARTIFACT_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging/artifacts}
# include all the origin test libs we need
if [ -f "$(dirname "${BASH_SOURCE[0]}" )/../lib/init.sh" ] ; then
    # disallow init.sh from calling setup_tmpdir_vars
    export OS_TMP_ENV_SET=origin-aggregated-logging
    source "$(dirname "${BASH_SOURCE[0]}" )/../lib/init.sh" # one stop shopping
    os::util::environment::setup_tmpdir_vars origin-aggregated-logging
else
    for lib in "${OS_ROOT}"/hack/{util.sh,text.sh} \
               "${OS_ROOT}"/hack/lib/*.sh "${OS_ROOT}"/hack/lib/**/*.sh
    do source "$lib"; done
fi

SERVER_CONFIG_DIR=/etc/origin
source $OS_O_A_L_DIR/hack/testing/prep-host

os::util::ensure::iptables_privileges_exist

os::log::info "Starting logging tests at `date`"

cd "${OS_ROOT}"

function cleanup() {
    return_code=$?
    if [ "$DEBUG_FAILURES" = "true" ] ; then
        echo debug failures - when you are finished, 'ps -ef|grep 987654' then kill that sleep process
        sleep 987654 || echo debugging done - continuing
    fi

    if [ "$DO_CLEANUP" = "true" ] ; then
        os::cleanup::all "${return_code}"
    else
        os::util::describe_return_code "${return_code}"
    fi

    exit "${return_code}"
}
trap "cleanup" EXIT

# override LOG_DIR and ARTIFACTS_DIR
os::util::environment::use_sudo
os::util::environment::setup_all_server_vars
os::util::environment::setup_time_vars

os::log::system::start

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
    # allow externalIPs in services
    cp ${SERVER_CONFIG_DIR}/master/master-config.yaml ${SERVER_CONFIG_DIR}/master/master-config.orig.yaml
    openshift ex config patch ${SERVER_CONFIG_DIR}/master/master-config.orig.yaml \
              --patch="{\"networkConfig\": {\"externalIPNetworkCIDRs\": [\"0.0.0.0/0\"]}}" > \
              ${SERVER_CONFIG_DIR}/master/master-config.yaml
    os::start::server
fi
export KUBECONFIG="${ADMIN_KUBECONFIG:-$MASTER_CONFIG_DIR/admin.kubeconfig}"
if [ ! -f $KUBECONFIG ] ; then
    if [ -d /etc/origin ] ; then
        SERVER_CONFIG_DIR=/etc/origin
        MASTER_CONFIG_DIR=$SERVER_CONFIG_DIR/master
        NODE_CONFIG_DIR=$SERVER_CONFIG_DIR/node-${KUBELET_HOST:-`hostname`}
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
    os::start::router
fi

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
    os::cmd::try_until_failure "oc describe pod $espod > /dev/null" "$(( 10 * TIME_MIN ))"
    # allow es to mount volumes from the host
    oadm policy add-scc-to-user hostmount-anyuid \
         system:serviceaccount:logging:aggregated-logging-elasticsearch
    if [ ! -d $2 ] ; then
        sudo mkdir -p $2
        sudo chown 1000:1000 $2
    fi
    oc volume dc/$es_dc --add --overwrite --name=elasticsearch-storage \
       --type=hostPath --path=$2
    if [ "${3:-}" = norollout ] ; then
        :
    else
        oc rollout latest dc/$es_dc
    fi
    oc rollout status -w dc/$es_dc
    os::cmd::expect_success "oc scale dc $es_dc --replicas=1"
    os::cmd::try_until_text "oc get pods -l component=$1" "Running" "$(( 10 * TIME_MIN ))"
}

configure_all_es_with_hostpath() {
    # es and es-ops need persistent storage
    configure_es_with_hostpath es $ES_VOLUME "$@"
    if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
        configure_es_with_hostpath es-ops $ES_OPS_VOLUME "$@"
    fi
}

dc_or_ds_name_to_image_name() {
    case $1 in
        logging-es-*) echo logging-elasticsearch ;;
        *) echo $1 ;;
    esac
}

update_image_in_configs() {
    # $1 is image prefix
    # $2 is version
    for dc in `oc get dc -o jsonpath='{.items[*].metadata.name}'`; do
        image_name=`dc_or_ds_name_to_image_name $dc`
        image_value=${1}${image_name}:${2:-latest}
        oc patch dc $dc --type=json --patch \
           '[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "'"$image_value"'"}]'
        oc rollout status -w dc/$dc
    done
    for ds in `oc get ds -o jsonpath='{.items[*].metadata.name}'`; do
        image_name=`dc_or_ds_name_to_image_name $ds`
        image_value=${1}${image_name}:${2:-latest}
        oc patch ds $ds --type=json --patch \
           '[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "'"$image_value"'"}]'
    done
    fpod=`get_running_pod fluentd`
    oc delete pod $fpod
}

os::test::junit::declare_suite_start "logging"
######### logging specific code starts here ####################
# not sure how/where this could be created before this . . .
if [ $NOSETUP = 1 ] ; then
    oc project logging > /dev/null
    # fix es to log to console
    oc get configmap logging-elasticsearch -o yaml | \
        sed 's/rootLogger:\(.*\)file/rootLogger:\1console/' | \
        oc replace -f -
    # build images from source
    source $OS_O_A_L_DIR/hack/testing/build-images
    # fix dc, ds to use new built images
    update_image_in_configs $imageprefix
    # set up es and es-ops to use a PV local disk
    configure_all_es_with_hostpath norollout
else
    oc get project logging > /dev/null 2>&1 || os::cmd::expect_success "oadm new-project logging --node-selector=''"
    os::cmd::expect_success "oc project logging > /dev/null"

    #initialize logging stack
    source $OS_O_A_L_DIR/hack/testing/init-log-stack
fi
source $OS_O_A_L_DIR/hack/testing/lib/test-functions

# see if expected pods are running
os::cmd::try_until_text "oc get pods -l component=es" "Running" "$(( 3 * TIME_MIN ))"
os::cmd::try_until_text "oc get pods -l component=kibana" "Running" "$(( 3 * TIME_MIN ))"
os::cmd::try_until_text "oc get pods -l component=curator" "Running" "$(( 3 * TIME_MIN ))"
if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
    # make sure the expected pods are running
    os::cmd::try_until_text "oc get pods -l component=es-ops" "Running" "$(( 3 * TIME_MIN ))"
    os::cmd::try_until_text "oc get pods -l component=kibana-ops" "Running" "$(( 3 * TIME_MIN ))"
    os::cmd::try_until_text "oc get pods -l component=curator-ops" "Running" "$(( 3 * TIME_MIN ))"
fi

if [ "${SETUP_ONLY:-}" = "true" ] ; then
    exit 0
fi

### run logging tests ###
os::cmd::expect_success "oc project logging > /dev/null"
pushd $OS_O_A_L_DIR/hack/testing
if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
    USE_CLUSTER=true
    ops_host=logging-es-ops
else
    USE_CLUSTER=
    ops_host=logging-es
fi

### many of the tests require the logging-fluentd-template ###
### remove this when we port the tests not to use the template ###
lfds=`mktemp`
oc get daemonset logging-fluentd -o yaml | grep -A 1 "nodeSelector:" | \
    sed 's/^/    /' > $lfds
# have to indent the value from the daemonset by 4 because we are inserting it
# into a template
sed "/serviceAccountName/r$lfds" $OS_O_A_L_DIR/deployer/templates/fluentd.yaml | \
oc new-app --param MASTER_URL=${MASTER_URL:-https://kubernetes.default.svc.cluster.local} \
   --param ES_HOST=logging-es --param OPS_HOST=$ops_host \
   --param IMAGE_VERSION_DEFAULT=latest --param IMAGE_PREFIX_DEFAULT=$imageprefix \
   --param USE_JOURNAL=${USE_JOURNAL:-""} \
   --param JOURNAL_SOURCE=${JOURNAL_SOURCE:-""} \
   --param JOURNAL_READ_FROM_HEAD=${JOURNAL_READ_FROM_HEAD:-false} \
   -f -
rm -f $lfds
### remove this when we port the tests not to use the template ###

# when fluentd starts up it may take a while before it catches up with all of the logs
# let's wait until that happens
wait_for_fluentd_ready
wait_for_fluentd_to_catch_up

# add admin user and normal user for kibana and token auth testing
export LOG_ADMIN_USER=admin
export LOG_ADMIN_PW=admin
export LOG_NORMAL_USER=loguser
export LOG_NORMAL_PW=loguser
os::cmd::expect_success "oc login --username=$LOG_ADMIN_USER --password=$LOG_ADMIN_PW"
os::cmd::expect_success "oc login --username=system:admin"
os::cmd::expect_success "oadm policy add-cluster-role-to-user cluster-admin $LOG_ADMIN_USER"
os::cmd::expect_success "oc login --username=$LOG_NORMAL_USER --password=$LOG_NORMAL_PW"
os::cmd::expect_success "oc login --username=system:admin"
os::cmd::expect_success "oc project logging > /dev/null"
os::cmd::expect_success "oadm policy add-role-to-user view $LOG_NORMAL_USER"
# also give $LOG_ADMIN_USER access to cluster stats
espod=`get_running_pod es`
wait_for_es_ready $espod 30 .searchguard.$espod/rolesmapping/0

oc exec $espod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
   --key /etc/elasticsearch/secret/admin-key \
   https://localhost:9200/.searchguard.$espod/rolesmapping/0 | \
    python -c 'import json, sys; hsh = json.loads(sys.stdin.read())["_source"]; hsh["sg_role_admin"]["users"].append("'$LOG_ADMIN_USER'"); print json.dumps(hsh)' | \
    oc exec -i $espod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
       --key /etc/elasticsearch/secret/admin-key \
       https://localhost:9200/.searchguard.$espod/rolesmapping/0 -XPUT -d@- | \
    python -mjson.tool
if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
    esopspod=`get_running_pod es-ops`
    wait_for_es_ready $esopspod 30 .searchguard.$esopspod/rolesmapping/0
    oc exec $esopspod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
       --key /etc/elasticsearch/secret/admin-key \
       https://localhost:9200/.searchguard.$esopspod/rolesmapping/0 | \
        python -c 'import json, sys; hsh = json.loads(sys.stdin.read())["_source"]; hsh["sg_role_admin"]["users"].append("'$LOG_ADMIN_USER'"); print json.dumps(hsh)' | \
        oc exec -i $esopspod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
           --key /etc/elasticsearch/secret/admin-key \
           https://localhost:9200/.searchguard.$esopspod/rolesmapping/0 -XPUT -d@- | \
        python -mjson.tool
fi

# verify that $LOG_ADMIN_USER user has access to cluster stats
sleep 5
get_test_user_token $LOG_ADMIN_USER $LOG_ADMIN_PW
oc project logging > /dev/null
kibpod=`get_running_pod kibana`
announce_test "Test '$LOG_ADMIN_USER' user can access cluster stats"
status=$(oc exec $kibpod -c kibana -- curl --connect-timeout 1 -s -k \
   --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
   -H "X-Proxy-Remote-User: $test_name" -H "Authorization: Bearer $test_token" -H "X-Forwarded-For: 127.0.0.1" \
   https://logging-es:9200/_cluster/health -o /dev/null -w '%{response_code}')
os::cmd::expect_success "test $status = 200"

if [ "$ENABLE_OPS_CLUSTER" = "true" ] ; then
    announce_test "Test '$LOG_ADMIN_USER' user can access cluster stats for OPS cluster"
    kibpod=`get_running_pod kibana-ops`
    status=$(oc exec $kibpod -c kibana -- curl --connect-timeout 1 -s -k \
       --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
       -H "X-Proxy-Remote-User: $test_name" -H "Authorization: Bearer $test_token" -H "X-Forwarded-For: 127.0.0.1" \
       https://logging-es-ops:9200/_cluster/health -o /dev/null -w '%{response_code}')
    os::cmd::expect_success "test $status = 200"
fi

# verify normal user has access to logging indices
get_test_user_token $LOG_NORMAL_USER $LOG_NORMAL_PW
oc project logging > /dev/null
nrecs=`curl_es_from_kibana $kibpod logging-es "project.logging." _count kubernetes.namespace_name logging | \
       get_count_from_json`
if [ ${nrecs:-0} -lt 1 ] ; then
    echo ERROR: $LOG_NORMAL_USER cannot access project.logging.* indices
    curl_es_from_kibana $kibpod logging-es "project.logging." _count message a | \
        python -mjson.tool
    exit 1
fi

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
        if [ $test = test-upgrade.sh ] ; then
            echo SKIPPING upgrade test for now
            continue
        fi
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

echo SKIPPING reinstall test for now
exit 0

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

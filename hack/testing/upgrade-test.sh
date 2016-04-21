#! /bin/bash

if [[ $VERBOSE ]]; then
  set -ex
else
  set -e
  # to make nounset happy
  VERBOSE=
fi
set -o nounset
set -o pipefail

if [[ $# -ne 1 || "$1" = "false" ]]; then
  # assuming not using OPS cluster
  CLUSTER="false"
else
  CLUSTER="$1"
  OPS="-ops"
fi

function removeCurator() {
  echo "removing curator"
  os::cmd::expect_success "oc delete dc logging-curator"
  os::cmd::expect_success "oc delete is logging-curator"

  curatorpod=$(oc get pod -l component=curator -o jsonpath='{.items[*].metadata.name}')
  os::cmd::try_until_failure "oc describe pod $curatorpod > /dev/null" "$(( 3 * TIME_MIN ))"
}

function useFluentdDC() {
  echo "installing fluentd DC"

  fluentdpod=$(oc get pod -l component=fluentd -o jsonpath='{.items[*].metadata.name}')
  ops_host=$(oc get pod $fluentdpod -o jsonpath='{.spec.containers[*].env[?(@.name=="OPS_HOST")].value}')
  ops_port=$(oc get pod $fluentdpod -o jsonpath='{.spec.containers[*].env[?(@.name=="OPS_PORT")].value}')

  os::cmd::expect_success "oc delete daemonset logging-fluentd"
  os::cmd::expect_success "oc delete template logging-fluentd-template"

  os::cmd::try_until_failure "oc describe pod $fluentdpod > /dev/null" "$(( 3 * TIME_MIN ))"

  os::cmd::expect_success "oc process -f templates/fluentd_dc.yaml \
     -v IMAGE_PREFIX_DEFAULT=$imageprefix,OPS_HOST=$ops_host,OPS_PORT=$ops_port | oc create -f -"

  os::cmd::expect_success "oc scale dc logging-fluentd --replicas=1"
  os::cmd::try_until_text "oc get pods -l component=fluentd" "Running" "$(( 3 * TIME_MIN ))"
}

function removeAdminCert() {
  echo "removing admin cert"

  # the upgrade script looks for
  # $(oc get secrets -o jsonpath='{.items[?(@.data.admin-cert)].metadata.name}')
  # to exist

  os::cmd::expect_success "oc patch secret logging-elasticsearch -p '{\"data\":{\"admin-cert\": null}}'"
}

function upgrade() {
  echo "running with upgrade mode"

  os::cmd::expect_success "oc new-app \
                        logging-deployer-template \
                        -p ENABLE_OPS_CLUSTER=$CLUSTER \
                        ${pvc_params} \
                        -p IMAGE_PREFIX=$imageprefix \
                        -p KIBANA_HOSTNAME=kibana.example.com \
                        -p ES_CLUSTER_SIZE=1 \
                        -p PUBLIC_MASTER_URL=https://localhost:8443${masterurlhack} \
                        -p MODE=upgrade"
  os::cmd::try_until_text "oc describe bc logging-deployment | awk '/^logging-deployment-/ {print \$2}'" "complete"
  os::cmd::try_until_text "oc get pods -l component=deployer" "Completed" "$(( 3 * TIME_MIN ))"

  os::cmd::try_until_text "oc get pods -l component=es" "Running" "$(( 3 * TIME_MIN ))"
  os::cmd::try_until_text "oc get pods -l component=kibana" "Running" "$(( 3 * TIME_MIN ))"
  os::cmd::try_until_text "oc get pods -l component=curator" "Running" "$(( 3 * TIME_MIN ))"
  os::cmd::try_until_text "oc get pods -l component=fluentd" "Running" "$(( 3 * TIME_MIN ))"
}
TEST_DIVIDER="------------------------------------------"

echo $TEST_DIVIDER
# test from base install
removeCurator
useFluentdDC
removeAdminCert
upgrade
./e2e-test.sh  $CLUSTER

echo $TEST_DIVIDER
# test from first upgrade
removeCurator
useFluentdDC
upgrade
./e2e-test.sh $CLUSTER

echo $TEST_DIVIDER
# test from half upgrade
removeCurator
upgrade
./e2e-test.sh  $CLUSTER

echo $TEST_DIVIDER
useFluentdDC
upgrade
./e2e-test.sh  $CLUSTER

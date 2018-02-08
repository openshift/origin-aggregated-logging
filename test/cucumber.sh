#!/bin/bash

# This is the entrypoint for running the cucumber tests
# as a job

OS_O_A_L_DIR=${OS_O_A_L_DIR:-$(dirname "${BASH_SOURCE[0]}" )/..}
source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::test::junit::declare_suite_start "test/cucumber"

ARTIFACT_DIR=${ARTIFACT_DIR:-/tmp/cucumber}
CUCUMBER_DIR="${OS_O_A_L_DIR}/test/cucumber"
CUCUMBER_BUILD_WAIT_TIME=${CUCUMBER_BUILD_WAIT_TIME:-$((15 * minute))}
CLEANUP="${CLEANUP:-true}"
SKIP_BUILD="${SKIP_BUILD:-false}"
SKIP_SETUP="${SKIP_SETUP:-false}"
LOGGING_NS="logging"

function setup() {
  api_host=$1
  #create resources
  os::cmd::expect_success "oc process -f ${CUCUMBER_DIR}/resources.yml | oc apply -n ${LOGGING_NS} -f -"


  if [ "false" = "${SKIP_BUILD}" ] ; then
    #build image
    os::cmd::expect_success "oc -n ${LOGGING_NS} start-build logging-cucumber --from-repo=${OS_O_A_L_DIR}"
    build="logging-cucumber-$(oc -n ${LOGGING_NS} get bc logging-cucumber -o jsonpath='{.status.lastVersion}')"
    os::cmd::try_until_text "oc -n ${LOGGING_NS} get build $build -o jsonpath='{.status.phase}'" "Complete|Failed|Error" $CUCUMBER_BUILD_WAIT_TIME
    os::cmd::expect_success_and_text "oc -n ${LOGGING_NS} get build $build -o jsonpath='{.status.phase}'" "Complete"
  fi

  kibana_url="kibana.${api_host}.nip.io"
  os::cmd::expect_success "oc -n ${LOGGING_NS} patch route logging-kibana -p '{\"spec\": {\"host\": \"${kibana_url}\"}}'"
  os::cmd::expect_success "oc -n ${LOGGING_NS} patch oauthclient kibana-proxy -p '{\"redirectURIs\": [\"${kibana_url}\"]}'"
}

os::cmd::expect_success "oc login -u system:admin"
os::cmd::expect_success "oc adm policy add-cluster-role-to-user cluster-admin admin"

es_pod_name=$(oc -n ${LOGGING_NS} get pod -l component=es -o jsonpath='{.items[0].metadata.name}' -n logging)
API_HOST=$(oc -n ${LOGGING_NS} exec -c elasticsearch $es_pod_name env | grep -oP 'KUBERNETES_SERVICE_HOST=\K(.*)')
API_PORT=$(oc -n ${LOGGING_NS} exec -c elasticsearch $es_pod_name env | grep -oP 'KUBERNETES_SERVICE_PORT=\K(.*)')

if [ "false" = "${SKIP_SETUP}" ] ; then
  setup $API_HOST
  if [ ! -d ${ARTIFACT_DIR} ] ; then
    mkdir -m 766 ${ARTIFACT_DIR}
  fi
fi


os::log::info Writing debug logs to dir: ${ARTIFACT_DIR}

VOLUME_OPTS="-v ${ARTIFACT_DIR}:/opt/app/src/log"
CUCUMBER_IMAGE="$(oc -n ${LOGGING_NS} get is logging-cucumber -o jsonpath={.status.dockerImageRepository}):latest"
ENV_OPTS="-e KUBERNETES_SERVICE_HOST=${API_HOST} -e KUBERNETES_SERVICE_PORT=${API_PORT}"
OPTS="${VOLUME_OPTS} ${ENV_OPTS} --privileged"
docker run ${OPTS} ${CUCUMBER_IMAGE}

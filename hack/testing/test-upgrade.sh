#!/bin/bash

if [[ $VERBOSE ]]; then
  set -ex
else
  set -e
  VERBOSE=
fi
set -o nounset
set -o pipefail

if [[ $# -ne 1 || "$1" = "false" ]]; then
  # assuming not using OPS cluster
  CLUSTER="false"
  ops=
else
  CLUSTER="$1"
  ops="-ops"
fi

ARTIFACT_DIR=${ARTIFACT_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging}
if [ ! -d $ARTIFACT_DIR ] ; then
    mkdir -p $ARTIFACT_DIR
fi

TEST_DIVIDER="------------------------------------------"
UPGRADE_POD=""

function removeCurator() {
  echo "removing curator"
  for curator_dc in $(oc get dc -l logging-infra=curator -o jsonpath='{.items[*].metadata.name}'); do
    os::cmd::expect_success "oc delete dc $curator_dc"
  done

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

  os::cmd::expect_success "oc new-app logging-fluentd-template"

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

function addTriggers() {
  echo "Adding triggers"

  # the upgrade script looks for
  # oc get dc -l logging-infra -o jsonpath='{.items[?(@.spec.triggers[*].type)].metadata.name}'
  # to exist

  for dc in $(oc get dc -l logging-infra -o jsonpath='{.items[*].metadata.name}'); do
    os::cmd::expect_success "oc patch dc/$dc -p '{ \"spec\": { \"triggers\": [{ \"type\" : \"ConfigChange\" }] } }'"
  done
}

function rebuildVersion() {
  # Rebuilding images so that the sha256 and tag are different than what was installed
  # so we can test patching

  local tag=${1:-latest}

  for bc in $(oc get bc -l logging-infra -o jsonpath='{.items[*].metadata.name}'); do
    os::cmd::expect_success "oc patch bc/$bc -p='{ \"spec\" : { \"output\" : { \"to\" : { \"name\" : \"'$bc':'$tag'\" } } } }'"

    if [ "$USE_LOCAL_SOURCE" = "true" ] ; then
      oc start-build --from-dir $OS_O_A_L_DIR $bc
    else
      oc start-build $bc
    fi
  done

  os::cmd::expect_success "wait_for_new_builds_complete"
}

function upgrade() {
  echo "running with upgrade mode"

  local version=${1:-latest}

  os::cmd::expect_success "oc new-app \
                        logging-deployer-template \
                        -p ENABLE_OPS_CLUSTER=$ENABLE_OPS_CLUSTER \
                        ${pvc_params} \
                        -p IMAGE_PREFIX=$imageprefix \
                        -p KIBANA_HOSTNAME=kibana.example.com \
                        -p ES_CLUSTER_SIZE=1 \
                        -p PUBLIC_MASTER_URL=https://localhost:8443${masterurlhack} \
                        -p MODE=upgrade \
                        -p IMAGE_VERSION=$version"

  UPGRADE_POD=$(get_latest_pod "component=deployer")
  os::cmd::try_until_text "oc get pods $UPGRADE_POD" "Completed" "$(( 20 * TIME_MIN ))"
}

# verify everything is at the latest state
# templates and DC patched
# admin cert/key/ca
# successful migration
# daemonset, no DC for fluentd
# curator
# no DC triggers
# no logging-infra=support IS exist
function verifyUpgrade() {

  local checkMigrate=${1:-false}

### check templates and DC patched
  for template in $(oc get template -l logging-infra -o name); do

    value=$(oc get $template -o jsonpath='{.parameters[?(@.name=="IMAGE_VERSION")].value}')

    [[ -z "$value" ]] && continue

    echo "Checking for template $template"
    [[ "$value" == "$version" ]] || return 1
  done

  # check all images in the dc
  # we check the readable tag and the tag's sha256
  echo "Checking DC IMAGE_VERSION matches deployer IMAGE_VERSION"
  for image in $(oc get dc -l logging-infra -o jsonpath='{.items[*].spec.template.spec.containers[*].image}'); do
    # values[0] is the image name
    # values[1] is the tag
    values=(`echo $image | sed 's/^.*\///g' | tr ":" " "`)
    name=$(echo ${values[0]} | sed 's/@.*$//g')
    value=${values[1]}

    sha=$(oc get is $name -o jsonpath='{.status.tags[?(@.tag=="'$version'")].items[*].image}' | sed 's/^.*://g')

    echo "Checking tag for $name"
    [[ "$value" == "$version" ]] || [[ "$value" == "$sha" ]] || return 1
  done

### check for admin-cert, admin-key, admin-ca
  [[ -z "$(oc get secret/logging-elasticsearch -o jsonpath='{.data.admin-ca}')" ]] && return 1
  [[ -z "$(oc get secret/logging-elasticsearch -o jsonpath='{.data.admin-key}')" ]] && return 1
  [[ -z "$(oc get secret/logging-elasticsearch -o jsonpath='{.data.admin-cert}')" ]] && return 1

### check that migration was successful
  if [ $checkMigrate = true ]; then
    [[ -z "$(oc logs $UPGRADE_POD | grep 'Migration for project test: {"acknowledged":true}')" ]] && return 1
    [[ -z "$(oc logs $UPGRADE_POD | grep 'Migration for project logging: {"acknowledged":true}')" ]] && return 1
  fi

### check for Fluentd daemonset, no DC exists
  [[ -z "$(oc get daemonset/logging-fluentd -o name)" ]] && return 1
  [[ -n "$(oc get dc -l logging-infra=fluentd -o name)" ]] && return 1

### check for Curator
  [[ -z "$(oc get dc -l logging-infra=curator -o name)" ]] && return 1

### check for no triggers in DC
  [[ -n "$(oc get dc -l logging-infra -o jsonpath='{.items[?(@.spec.triggers[*].type)].metadata.name}')" ]] && return 1

### make sure we have everything running
  os::cmd::try_until_text "oc get pods -l component=es" "Running" "$(( 3 * TIME_MIN ))"
  os::cmd::try_until_text "oc get pods -l component=kibana" "Running" "$(( 3 * TIME_MIN ))"
  os::cmd::try_until_text "oc get pods -l component=fluentd" "Running" "$(( 3 * TIME_MIN ))"
  os::cmd::try_until_text "oc get pods -l component=curator" "Running" "$(( 3 * TIME_MIN ))"
}

source "./logging.sh"

echo $TEST_DIVIDER
# test from base install
removeAdminCert && \
removeCurator && \
useFluentdDC && \
addTriggers && \
rebuildVersion "upgraded" && \

upgrade "upgraded" && \
verifyUpgrade true && \

./e2e-test.sh $USE_CLUSTER && \

echo $TEST_DIVIDER
# test from partial upgrade
useFluentdDC && \
addTriggers && \
upgrade "upgraded" && \
verifyUpgrade && \

./e2e-test.sh $USE_CLUSTER && \
exit 0

oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
exit 1

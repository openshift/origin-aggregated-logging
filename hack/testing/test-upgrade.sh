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

function dumpEvents() {
  oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
}
trap dumpEvents EXIT

function removeEsCuratorConfigMaps() {
  echo "removing configmaps from ES and Curator"
  # construct patch for ES
  local dc patch=$(join , \
    '{"op": "replace", "path": "/spec/template/spec/containers/0/volumeMounts/0/mountPath", "value": "/etc/elasticsearch/keys"}' \
    '{"op": "remove", "path": "/spec/template/spec/containers/0/volumeMounts/1"}' \
    '{"op": "remove", "path": "/spec/template/spec/volumes/1"}' \
  )
  for dc in $(get_es_dcs); do
    oc patch $dc --type=json --patch "[$patch]" || return 1
  done
  # construct patch for curator
  patch=$(join , \
    '{"op": "remove", "path": "/spec/template/spec/containers/0/volumeMounts/1"}' \
    '{"op": "remove", "path": "/spec/template/spec/volumes/1"}' \
  )
  for dc in $(get_curator_dcs); do
    oc patch $dc --type=json --patch "[$patch]" || return 1
  done
  # delete the actual configmaps
  oc delete configmap/logging-elasticsearch configmap/logging-curator || return 1

  return 0
}

function waitFor() {

  local statement=$1
  local TIMES=${2:-300}
  local failure=${3:-false}

  for (( i=1; i<=$TIMES; i++ )); do
    eval "$statement" && return 0
    eval "$failure" && return 1
    sleep 1
  done
  return 1
}

function removeCurator() {
  echo "removing curator"
  for curator_dc in $(oc get dc -l logging-infra=curator -o jsonpath='{.items[*].metadata.name}'); do
    oc delete dc $curator_dc || return 1
  done

  waitFor "[[ -z \"\$(oc get pod -l component=curator -o name)\" ]]" "$(( 3 * TIME_MIN ))"
}

function useFluentdDC() {
  echo "installing fluentd DC"

  fluentdpod=$(oc get pod -l component=fluentd -o jsonpath='{.items[*].metadata.name}')
  ops_host=$(oc get pod $fluentdpod -o jsonpath='{.spec.containers[*].env[?(@.name=="OPS_HOST")].value}')
  ops_port=$(oc get pod $fluentdpod -o jsonpath='{.spec.containers[*].env[?(@.name=="OPS_PORT")].value}')

  oc delete daemonset logging-fluentd
  oc delete template logging-fluentd-template

  waitFor "[[ -z \"\$(oc get pod \$fluentdpod -o name)\" ]]" "$(( 3 * TIME_MIN ))"

  oc process -f templates/fluentd_dc.yaml \
     -v IMAGE_PREFIX_DEFAULT=$imageprefix,OPS_HOST=$ops_host,OPS_PORT=$ops_port | oc create -f -

  oc new-app logging-fluentd-template

  oc scale dc logging-fluentd --replicas=1
  waitFor "[[ \"Running\" == \"\$(oc get pods -l component=fluentd -o jsonpath='{.items[*].status.phase}')\" ]]" "$(( 3 * TIME_MIN ))" && return 0
  return 1
}

function removeAdminCert() {
  echo "removing admin cert"

  # the upgrade script looks for
  # $(oc get secrets -o jsonpath='{.items[?(@.data.admin-cert)].metadata.name}')
  # to exist

  oc patch secret logging-elasticsearch -p '{"data":{"admin-cert": null}}'

  return 0
}

function addTriggers() {
  echo "Adding triggers"

  # the upgrade script looks for
  # oc get dc -l logging-infra -o jsonpath='{.items[?(@.spec.triggers[*].type)].metadata.name}'
  # to exist

  for dc in $(oc get dc -l logging-infra -o jsonpath='{.items[*].metadata.name}'); do
    oc patch dc/$dc -p '{ "spec": { "triggers": [{ "type" : "ConfigChange" }] } }'
  done
  return 0
}

function rebuildVersion() {
  # Rebuilding images so that the sha256 and tag are different than what was installed
  # so we can test patching

  local tag=${1:-latest}

  for bc in $(oc get bc -l logging-infra -o jsonpath='{.items[*].metadata.name}'); do
    oc patch bc/$bc -p='{ "spec" : { "output" : { "to" : { "name" : "'$bc':'$tag'" } } } }'

    if [ "$USE_LOCAL_SOURCE" = "true" ] ; then
      oc start-build --from-dir $OS_O_A_L_DIR $bc
    else
      oc start-build $bc
    fi
  done

  wait_for_new_builds_complete && return 0
  return 1
}

function upgrade() {
  echo "running with upgrade mode"

  local version=${1:-latest}

  oc new-app logging-deployer-template \
                        -p ENABLE_OPS_CLUSTER=$ENABLE_OPS_CLUSTER \
                        ${pvc_params} \
                        -p IMAGE_PREFIX=$imageprefix \
                        -p KIBANA_HOSTNAME=kibana.example.com \
                        -p ES_CLUSTER_SIZE=1 \
                        -p PUBLIC_MASTER_URL=https://localhost:8443${masterurlhack} \
                        -p MODE=upgrade \
                        -p IMAGE_VERSION=$version

  UPGRADE_POD=$(get_latest_pod "logging-infra=deployer")
  waitFor "[[ \"Succeeded\" == \"\$(oc get pod $UPGRADE_POD -o jsonpath='{.status.phase}')\" ]]" "$(( 20 * TIME_MIN ))" "[[ \"Failed\" == \"\$(oc get pod $UPGRADE_POD -o jsonpath='{.status.phase}')\" ]]" && return 0

  return 1
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

  local version=${1:-latest}
  local checkMigrate=${2:-false}

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
    for project in $(oc get projects -o 'jsonpath={.items[*].metadata.name}'); do
      [[ "default openshift openshift-infra" =~ $project ]] && continue
      [[ -z "$(oc logs $UPGRADE_POD | grep 'Migration for project '$project': {"acknowledged":true}')" ]] && return 1
    done

  fi

### check for Fluentd daemonset, no DC exists
  [[ -z "$(oc get daemonset/logging-fluentd -o name)" ]] && return 1
  [[ -n "$(oc get dc -l logging-infra=fluentd -o name)" ]] && return 1

### check for Curator
  [[ -z "$(oc get dc -l logging-infra=curator -o name)" ]] && return 1

### check for no triggers in DC
  [[ -n "$(oc get dc -l logging-infra -o jsonpath='{.items[?(@.spec.triggers[*].type)].metadata.name}')" ]] && return 1

### make sure we have everything running
  waitFor "[[ \"Running\" == \"\$(oc get pods -l component=es -o jsonpath='{.items[*].status.phase}')\" ]]" "$(( 3 * TIME_MIN ))" || return 1
  waitFor "[[ \"Running\" == \"\$(oc get pods -l component=kibana -o jsonpath='{.items[*].status.phase}')\" ]]" "$(( 3 * TIME_MIN ))" || return 1
  waitFor "[[ \"Running\" == \"\$(oc get pods -l component=fluentd -o jsonpath='{.items[*].status.phase}')\" ]]" "$(( 3 * TIME_MIN ))" || return 1
  waitFor "[[ \"Running\" == \"\$(oc get pods -l component=curator -o jsonpath='{.items[*].status.phase}')\" ]]" "$(( 3 * TIME_MIN ))" || return 1

  if [ $ENABLE_OPS_CLUSTER = true ]; then
    waitFor "[[ \"Running\" == \"\$(oc get pods -l component=es-ops -o jsonpath='{.items[*].status.phase}')\" ]]" "$(( 3 * TIME_MIN ))" || return 1
    waitFor "[[ \"Running\" == \"\$(oc get pods -l component=kibana-ops -o jsonpath='{.items[*].status.phase}')\" ]]" "$(( 3 * TIME_MIN ))" || return 1
    waitFor "[[ \"Running\" == \"\$(oc get pods -l component=curator-ops -o jsonpath='{.items[*].status.phase}')\" ]]" "$(( 3 * TIME_MIN ))" || return 1
  fi

  return 0
}
# this is treated differently than how it is in logging.sh -- set it to be in seconds
TIME_MIN=60

echo $TEST_DIVIDER
# test from base install
removeEsCuratorConfigMaps
removeAdminCert
removeCurator
useFluentdDC
addTriggers
rebuildVersion "upgraded"

upgrade "upgraded"
verifyUpgrade "upgraded" true

./e2e-test.sh $USE_CLUSTER

echo $TEST_DIVIDER
# test from partial upgrade
removeEsCuratorConfigMaps
useFluentdDC
addTriggers
upgrade "upgraded"
verifyUpgrade "upgraded"

./e2e-test.sh $USE_CLUSTER

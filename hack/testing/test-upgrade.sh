#!/bin/bash

if [ -n "${VERBOSE:-}" ] ; then
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

if [ "function" = "`type -t get_es_dcs 2> /dev/null`" ] ; then
    : # already sourced
else
    source ../../deployer/scripts/util.sh
fi

if [ -z "${imageprefix:-}" ] ; then
    imageprefix=`oc get is | awk '$1 == "logging-deployment" {print gensub(/^([^/]*\/logging\/).*$/, "\\\1", 1, $2)}'`
fi

USE_LOCAL_SOURCE=${USE_LOCAL_SOURCE:-true}
OS_O_A_L_DIR=${OS_O_A_L_DIR:-$(dirname "${BASH_SOURCE}")/../..}
ENABLE_OPS_CLUSTER=${ENABLE_OPS_CLUSTER:-$CLUSTER}
masterurlhack=${masterurlhack:-"-p MASTER_URL=https://172.30.0.1:443"}
my_pvc_params=""
if [ "$ENABLE_OPS_CLUSTER" = "true" ]; then
    my_pvc_params="-p ES_OPS_PVC_SIZE=10 -p ES_OPS_PVC_PREFIX=es-ops-pvc-"
fi
pvc_params=${pvc_params:-$my_pvc_params}

TEST_DIVIDER="------------------------------------------"
UPGRADE_POD=""
OPS_PROJECTS=("default" "openshift" "openshift-infra" "kube-system")

function dumpEvents() {
  oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
}
trap dumpEvents EXIT

function createOldIndexPattern() {
  echo "creating index with old pattern"

  indexDate=`date +%Y.%m.%d`
  genUUID=$(oc get project "oldindex" -o jsonpath='{.metadata.uid}')

  esPod=`oc get pods -l component=es -o name | sed "s,pod/,,"`

  waitFor "[[ \"Running\" == \"\$(oc get pods -l component=es -o jsonpath='{.items[*].status.phase}')\" ]]" "$(( 3 * TIME_MIN ))" || return 1
  [ -z "$esPod" ] && echo "Unable to find ES pod for recreating old index pattern" && return 1

  # create an old index pattern
  oldindex="oldindex.${genUUID}.${indexDate}"
  oc exec $esPod -- curl -s --cacert /etc/elasticsearch/secret/admin-ca --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key \
                         -XPUT "https://localhost:9200/$oldindex" -d '{ "settings": { "index": { "number_of_shards": 1, "number_of_replicas": 0 } } }'

  # create a bad alias for the old index
  badalias="project.oldindex.${genUUID}.*"
  oc exec $esPod -- curl -s --cacert /etc/elasticsearch/secret/admin-ca --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key \
                         -XPOST "https://localhost:9200/_aliases" -d '{"actions":[{"add":{"index":"'"$oldindex"'","alias":"'"$badalias"'"}}]}'

  # necessary?
  oc exec $esPod -- curl -s --cacert /etc/elasticsearch/secret/admin-ca --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key \
                         -XGET "https://localhost:9200/_cluster/health/oldindex.${genUUID}.${indexDate}?wait_for_status=yellow&timeout=50s"
}

function deleteOldIndexPattern() {
  echo "deleting index with old pattern"
  # delete an old index pattern
  esPod=`oc get pods -l component=es -o name | sed "s,pod/,,"`
  oc exec $esPod -- curl -s --cacert /etc/elasticsearch/secret/admin-ca --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key \
     -XDELETE "https://logging-es:9200/oldindex.*"
}

function removeFluentdConfigMaps() {
  echo "removing configmaps from fluentd template"
  # construct patch for template
  local patch=$(join , \
    '{"op": "remove", "path": "/objects/0/spec/template/spec/containers/0/volumeMounts/2"}' \
    '{"op": "remove", "path": "/objects/0/spec/template/spec/volumes/2"}' \
  )
  oc patch template/logging-fluentd-template --type=json --patch "[$patch]" || return 1
  oc delete configmap/logging-fluentd || return 1
  return 0
}

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
     -v IMAGE_PREFIX_DEFAULT=$imageprefix -v OPS_HOST=$ops_host -v OPS_PORT=$ops_port | oc create -f -

  oc new-app logging-fluentd-template

  oc scale dc logging-fluentd --replicas=1
  oc deploy dc/logging-fluentd --latest || :
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
                        -p PUBLIC_MASTER_URL=https://localhost:8443 ${masterurlhack} \
                        -p MODE=upgrade \
                        -p IMAGE_VERSION=$version

  UPGRADE_POD=$(get_latest_pod "logging-infra=deployer")
  waitFor "[[ \"Succeeded\" == \"\$(oc get pod $UPGRADE_POD -o jsonpath='{.status.phase}')\" ]]" "$(( 20 * TIME_MIN ))" "[[ \"Failed\" == \"\$(oc get pod $UPGRADE_POD -o jsonpath='{.status.phase}')\" ]]" && return 0

  return 1
}

function findBrokenAliases() {
    local espod=$(oc get pods -l component=es -o jsonpath='{.items[0].metadata.name}')
    namerx='[^.][^.]*'
    uuidrx='[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}'
    set -o pipefail
    if oc exec $espod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
          --key /etc/elasticsearch/secret/admin-key \
          https://localhost:9200/_cat/aliases | \
            awk -v projrx="^project[.]${namerx}[.]${uuidrx}[.][*]\$" '$1 ~ projrx {exit 1}' ; then
        echo good - found no broken aliases
    else
        echo ERROR: found broken aliases
        oc exec $espod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
          --key /etc/elasticsearch/secret/admin-key \
          https://localhost:9200/_cat/aliases | \
            awk -v projrx="^project[.]${namerx}[.]${uuidrx}[.][*]\$" '$1 ~ projrx {print}'
        set +o pipefail
        return 1
    fi
    set +o pipefail
    return 0
}

function findGoodAliases() {
    local espod=$(oc get pods -l component=es -o jsonpath='{.items[0].metadata.name}')
    uuidrx='[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}'
    set -o pipefail
    if oc exec $espod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
          --key /etc/elasticsearch/secret/admin-key \
          https://localhost:9200/_cat/aliases | \
            awk -v projrx="^project[.]oldindex[.]${uuidrx}[.]cdm-alias[.]" '$1 ~ projrx {exit 1}' ; then
        echo ERROR: did not find good alias
        oc exec $espod -- curl -s -k --cert /etc/elasticsearch/secret/admin-cert \
          --key /etc/elasticsearch/secret/admin-key \
          https://localhost:9200/_cat/aliases
        set +o pipefail
        return 1
    else
        echo good - found good alias
    fi
    set +o pipefail
    return 0
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
  local checkCDMMigrate=${3:-false}

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
      [[ "${OPS_PROJECTS[@]}" =~ $project ]] && continue
      [[ -n "$(oc logs $UPGRADE_POD | grep 'Migration skipped for project '$project' - using common data model')" ]] && continue
      [[ -n "$(oc logs $UPGRADE_POD | grep 'Migration skipped for project '$project' - no index')" ]] && continue
      [[ -z "$(oc logs $UPGRADE_POD | grep 'Migration for project '$project': {"acknowledged":true}')" ]] && return 1
    done
  fi

  if [ $checkCDMMigrate = true ]; then
    [[ -n "$(oc logs $UPGRADE_POD | grep 'Migration skipped for project oldindex.'${genUUID}'.'${indexDate}' - using common data model')" ]] && return 1
    [[ -z "$(oc logs $UPGRADE_POD | grep '^INFO: update succeeded')" ]] && return 1
    [[ -z "$(oc logs $UPGRADE_POD | grep '^Done - removed 1 broken aliases')" ]] && return 1
    [[ -z "$(oc logs $UPGRADE_POD | grep '^Done - created aliases for 1 old-style indices')" ]] && return 1
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
  if [ $checkCDMMigrate = true ]; then
      findBrokenAliases
      findGoodAliases
  fi
  # check elasticsearch has kibana mappings
  oc get configmap logging-elasticsearch -o yaml | grep -q io.fabric8.elasticsearch.kibana.mapping.app
  oc get configmap logging-elasticsearch -o yaml | grep -q io.fabric8.elasticsearch.kibana.mapping.ops
  # check fluentd has common data model
  oc get configmap logging-fluentd -o yaml | grep -q configs.d/openshift/filter-common-data-model.conf

  return 0
}
# this is treated differently than how it is in logging.sh -- set it to be in seconds
TIME_MIN=60

echo $TEST_DIVIDER
oc get project oldindex > /dev/null 2>&1 || oadm new-project oldindex --node-selector='' && sleep 5
# test from base install
createOldIndexPattern
removeFluentdConfigMaps
removeEsCuratorConfigMaps
removeAdminCert
removeCurator
useFluentdDC
addTriggers
rebuildVersion "upgraded"

upgrade "upgraded"
verifyUpgrade "upgraded" true true

./e2e-test.sh ${USE_CLUSTER:-$CLUSTER}

echo $TEST_DIVIDER
# test from partial upgrade
createOldIndexPattern
removeFluentdConfigMaps
removeEsCuratorConfigMaps
useFluentdDC
addTriggers

upgrade "upgraded"
verifyUpgrade "upgraded"

./e2e-test.sh ${USE_CLUSTER:-$CLUSTER}

deleteOldIndexPattern
oc delete project oldindex || :

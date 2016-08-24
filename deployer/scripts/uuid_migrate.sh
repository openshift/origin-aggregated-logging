#! /bin/bash

function uuid_migrate() {
  set -exuo pipefail
  initialize_es_vars
  recreate_admin_certs
  create_context
  run_uuid_migration
}

function initialize_es_vars() {
  OPS_PROJECTS=("default" "openshift" "openshift-infra" "kube-system")
  CA=$dir/admin-ca.crt
  KEY=$dir/admin-key.key
  CERT=$dir/admin-cert.crt
  PROJ_PREFIX=${PROJ_PREFIX:-project.}

  es_host=${ES_HOST:-logging-es}
  es_port=${ES_PORT:-9200}
}

function create_alias() {
    local output=""
    # first, see if ${PROJ_PREFIX}$1.$2 exists - if so, assume that we do not have to create
    # this uuid alias
    set +o pipefail
    if curl -s --cacert $CA --key $KEY --cert $CERT "https://$es_host:$es_port/${PROJ_PREFIX}$1.$2.*" | python -mjson.tool 2> /dev/null | grep -q '"'${PROJ_PREFIX}$1.$2'[.]' ; then
        echo Migration skipped for project $1 - using common data model
        set -o pipefail
        return 0
    fi
    set -o pipefail
    output=$(curl -s --cacert $CA --key $KEY --cert $CERT -XPOST "https://$es_host:$es_port/_aliases" -d "{ \"actions\": [ { \"add\": { \"index\": \"${1}.*\", \"alias\": \"${1}.${2}.reference\"}} ] }")

    echo Migration for project $1: $output
}

function create_context() {

  # there's no good way for oc to filter the list of secrets; and there can be several token secrets per SA.
  # following template prints all tokens for aggregated-logging-fluentd; --sort-by will order them earliest to latest, we will use the last.
  local sa_token_secret_template='{{range .items}}{{if eq .type "kubernetes.io/service-account-token"}}{{if eq "aggregated-logging-fluentd" (index .metadata.annotations "kubernetes.io/service-account.name")}}{{.data.token}}
{{end}}{{end}}{{end}}'
  local failure="false"
  local nodes_active="false"
  local output=""

  # check that the aggregated-logging-fluentd SA exists and we can get its token
  output=$(oc get secret --namespace="${project}" --sort-by=metadata.resourceVersion --template="$sa_token_secret_template" 2>&1)
  local token=$(echo -e "$output" | tail -1 | base64 -d)

  # set up a config context using the aggregated-logging-fluentd account and most recent token
  oc config set-credentials aggregated-logging-fluentd-account \
    --token="$token" >& /dev/null
  oc config set-context aggregated-logging-fluentd-context \
    --cluster=master \
    --user=aggregated-logging-fluentd-account \
    --namespace="${project}" >& /dev/null

  oc config use-context aggregated-logging-fluentd-context
}

function recreate_admin_certs(){
  # lets not broadcast what our keys are for security reasons...
  usingx=$(echo $- | grep x) || :
  if [[ -n "$usingx" ]]; then
    set +x
  fi
# note: following mess is because we want the error output from the first failure, not a pipeline
  secret_ca=$(oc get secret/logging-elasticsearch --template='{{index .data "admin-ca"}}' 2>&1)
  secret_ca=$(echo -e "$secret_ca" | base64 -d 2>&1)

  secret_cert=$(oc get secret/logging-elasticsearch --template='{{index .data "admin-cert"}}' 2>&1)
  secret_cert=$(echo -e "$secret_cert" | base64 -d 2>&1)

  secret_key=$(oc get secret/logging-elasticsearch --template='{{index .data "admin-key"}}' 2>&1)
  secret_key=$(echo -e "$secret_key" | base64 -d 2>&1)

  echo -e "$secret_key" > $dir/admin-key.key
  echo -e "$secret_cert" > $dir/admin-cert.crt
  echo -e "$secret_ca" > $dir/admin-ca.crt

  if [[ -n "$usingx" ]]; then
    set -x
  fi
}

function run_uuid_migration() {

  if [[ -z "$(oc get pods -l component=es -o jsonpath='{.items[?(@.status.phase == "Running")].metadata.name}')" ]]; then
    echo "No Elasticsearch pods found running.  Cannot migrate."
    echo "Scale up ES prior to running with MODE=migrate"
    exit 1
  fi

  for index in $(oc get project -o jsonpath='{.items[*].metadata.name}'); do

    [[ "${OPS_PROJECTS[@]}" =~ "$index" ]] && continue

    uid=$(oc get project "$index" -o jsonpath='{.metadata.uid}')
    create_alias $index $uid

  done
}

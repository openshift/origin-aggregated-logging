#!/bin/bash
# This test is a smoke test to provide sanity the existing images
# are deployable using the latest operators.

set -euo pipefail

current_dir=$(dirname "${BASH_SOURCE[0]}" )
repo_dir=${repodir:-"$current_dir/../.."}
source ${current_dir}/common

ARTIFACT_DIR=${ARTIFACT_DIR:-$repo_dir/_output}
LOGGING_NS=${LOGGING_NS:-openshift-logging}

test_name=$(basename $0)
cleanup() {
    local return_code="$?"
    set +e
	if [ "${DO_CLEANUP:-true}" == "true" ] ; then
		mkdir -p $ARTIFACT_DIR/$test_name
		oc -n $LOGGING_NS get configmap fluentd -o jsonpath={.data} --ignore-not-found > $ARTIFACT_DIR/$test_name/fluent-configmap.log ||:
		get_all_logging_pod_logs $ARTIFACT_DIR/$test_name

		log::info "Removing test namespaces...."
		oc delete ns/openshift-logging ns/openshift-operators-redhat --force --grace-period=0
		for item in "ns/openshift-logging" "ns/openshift-operators-redhat"; do
			try_until_failure "oc get ${item}" "$((1 * $minute))"
		done
	fi
    exit $return_code
}
trap "cleanup" EXIT

if [ "${DO_SETUP:-true}" == "true" ] ; then
	log::info "Deploying cluster logging..."
	${repo_dir}/hack/deploy-logging.sh
fi

log::info "Checking deployment of elasticsearch..."
for pod in $(oc -n $LOGGING_NS get pods -l component=elasticsearch -o jsonpath={.items[*].metadata.name}); do
	log::info "Testing Elasticsearch pod ${pod}..."
	try_until_text "oc -n $LOGGING_NS exec -c elasticsearch ${pod} -- es_util --query=/ --request HEAD --head --output /dev/null --write-out %{response_code}" "200" "$(( 1*$minute ))"

	log::info "Checking that Elasticsearch pod ${pod} recovered its indices after starting..."
	try_until_text "oc -n $LOGGING_NS exec -c elasticsearch ${pod} -- es_util --query=_cluster/state/master_node --output /dev/null -w %{response_code}" "200" "$(( 2*$minute ))"
	es_master_id="$(oc -n $LOGGING_NS exec -c elasticsearch ${pod} -- es_util --query=_cluster/state/master_node | python -c  'import json, sys; print json.load(sys.stdin)["master_node"];' )"
	es_pod_node_id="$(oc -n $LOGGING_NS exec -c elasticsearch ${pod} -- es_util --query=_nodes/_local | python -c  'import json, sys; print json.load(sys.stdin)["nodes"].keys()[0];' )"
	es_detected_master_id="$(oc -n $LOGGING_NS exec -c elasticsearch ${pod} -- es_util --query=_cat/master?h=id )"
	if [[ "${es_master_id}" == "${es_pod_node_id}" ]]; then
		log::info "Elasticsearch pod ${pod} is the master"
	elif [[ -n "${es_detected_master_id}" ]]; then
		log::info "Elasticsearch pod ${pod} was able to detect a master"
	else
		log::fatal "Elasticsearch pod ${pod} isn't master and was unable to detect a master"
	fi
done

log::info "Checking deployment of kibana..."
#HACK there should only be one
try_until_text "oc -n $LOGGING_NS get pods -l component=kibana --no-headers | wc -l" "1" "$(( 3*$minute ))"
try_until_text "oc -n $LOGGING_NS get pod $(oc -n $LOGGING_NS get pods -l component=kibana -o jsonpath={.items[0].metadata.name}) -o jsonpath='{.status.conditions[?(@.type==\"ContainersReady\")].status}'" "True" "$(( 1*$minute ))"

log::info "Check to see if we have expected indices..."
pod=$(oc -n $LOGGING_NS get pods -l component=elasticsearch -o jsonpath={.items[0].metadata.name})
indices=$(oc -n $LOGGING_NS exec -c elasticsearch ${pod} -- indices)
log::info "Verify security index existence..."
echo "$indices" | grep \.security

log::info "Verify kibana index existence..."
echo "$indices" | grep \.kibana

log::info "Check to see if we have any data indices...implies collector is working"
echo "$indices" | grep -Ev "(\.kibana.*|\.security)"

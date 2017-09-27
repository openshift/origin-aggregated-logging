#!/bin/bash

# This functionality test ensures that:
#  - Elasticsearch and Kibana pods have started
#    successfully
#  - Elasticsearch is reachable from Kibana
#  - the Kibana-proxy is working
#  - the Kibana cert and key are functional
#  - indices have been successfully created by Fluentd
#    in Elasticsearch
#  - Expected plugins are installed on every Elasticsearch node
#  - Prometheus exporter plugin yields metrics
#
# This script expects the following environment
# variables:
#  - OAL_{
#         ELASTICSEARCH,
#         KIBANA
#         }_COMPONENT: the component labels that
#    are used to identify application pods
#  - OAL_ELASTICSEARCH_SERVICE: the service under which
#    Elasticsearch is exposed
#  - OAL_QUERY_SIZE: the number of messages to query
#    for per index
#  - OAL_TEST_IP: the IP address to test forwarding for
#  - LOG_ADMIN_{
#               USER
#               PW
#               }: credentials for the admin user
source "$(dirname "${BASH_SOURCE[0]}" )/../../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"

trap os::test::junit::reconcile_output EXIT
os::util::environment::setup_time_vars

query_size="${OAL_QUERY_SIZE:-"500"}"
test_ip="${OAL_TEST_IP:-"127.0.0.1"}"

os::test::junit::declare_suite_start "test/cluster/functionality"

# We need to use a name and token for logging checks later,
# so we have to provision a user with a token for this.
# TODO: Why is this necessary?
os::cmd::expect_success "oc login --username=${LOG_ADMIN_USER:-admin} --password=${LOG_ADMIN_PW:-admin}"
test_user="$( oc whoami )"
test_token="$( oc whoami -t )"

os::cmd::expect_success "oc login --username=system:admin"
os::cmd::expect_success "oc project logging"

# We can reach the Elasticsearch service at serviceName:apiPort
elasticsearch_api="$( oc get svc "${OAL_ELASTICSEARCH_SERVICE}" -o jsonpath='{ .metadata.name }:{ .spec.ports[?(@.targetPort=="restapi")].port }' )"

for kibana_pod in $( oc get pods --selector component="${OAL_KIBANA_COMPONENT}"  -o jsonpath='{ .items[*].metadata.name }' ); do
	os::log::info "Testing Kibana pod ${kibana_pod} for a successful start..."
	os::cmd::try_until_text "oc exec ${kibana_pod} -c kibana -- curl --silent --request HEAD --head --output /dev/null --write-out '%{response_code}' http://localhost:5601/" "200" "$(( 10*TIME_MIN ))"
	os::cmd::try_until_text "oc get pod ${kibana_pod} -o jsonpath='{ .status.containerStatuses[?(@.name==\"kibana\")].ready }'" "true"
	os::cmd::try_until_text "oc get pod ${kibana_pod} -o jsonpath='{ .status.containerStatuses[?(@.name==\"kibana-proxy\")].ready }'" "true"
done

for elasticsearch_pod in $( oc get pods --selector component="${OAL_ELASTICSEARCH_COMPONENT}" -o jsonpath='{ .items[*].metadata.name }' ); do
	os::log::info "Testing Elasticsearch pod ${elasticsearch_pod} for a successful start..."
	os::cmd::try_until_text "curl_es '${elasticsearch_pod}' '/' --request HEAD --head --output /dev/null --write-out '%{response_code}'" '200' "$(( 10*TIME_MIN ))"
	os::cmd::try_until_text "oc get pod ${elasticsearch_pod} -o jsonpath='{ .status.containerStatuses[?(@.name==\"elasticsearch\")].ready }'" "true"

	os::log::info "Checking that Elasticsearch pod ${elasticsearch_pod} recovered its indices after starting..."
	os::cmd::try_until_text "curl_es '${elasticsearch_pod}' '/_cluster/state/master_node' -w '%{response_code}'" "}200$" "$(( 10*TIME_MIN ))"
	es_master_id="$( curl_es "${elasticsearch_pod}" "/_cluster/state/master_node" | python -c  'import json, sys; print json.load(sys.stdin)["master_node"];' )"
	es_pod_node_id="$( curl_es "${elasticsearch_pod}" "/_nodes/_local" | python -c  'import json, sys; print json.load(sys.stdin)["nodes"].keys()[0];' )"
	es_detected_master_id="$( curl_es "${elasticsearch_pod}" "/_cat/master?h=id" )"
	if [[ "${es_master_id}" == "${es_pod_node_id}" ]]; then
		os::log::info "Elasticsearch pod ${elasticsearch_pod} is the master"
	elif [[ -n "${es_detected_master_id}" ]]; then
		os::log::info "Elasticsearch pod ${elasticsearch_pod} was able to detect a master"
	else
		os::log::fatal "Elasticsearch pod ${elasticsearch_pod} isn't master and was unable to detect a master"
	fi

	os::log::info "Checking that Elasticsearch pod ${elasticsearch_pod} has persisted indices created by Fluentd..."
	os::cmd::try_until_text "curl_es '${elasticsearch_pod}' '/_cat/indices?h=index'" "^(project|\.operations)\." "$(( 10*TIME_MIN ))"
	# We are interested in indices with one of the following formats:
	#     .operations.<year>.<month>.<day>
	#     project.<namespace>.<uuid>.<year>.<month>.<day>
	for index in $( curl_es "${elasticsearch_pod}" '/_cat/indices?h=index' ); do
		if [[ "${index}" == ".operations"* ]]; then
			# If this is an operations index, we will be searching
			# the journal for it
			index_search_path="journal"
		elif [[ "${index}" == "project."* ]]; then
			# Otherwise, we will find it in the container log, which
			# we can identify with the UUID
			uuid="$( cut -d '.' -f 3 <<<"${index}" )"
			index_search_path="/var/log/containers/*_${uuid}_*.log"
		else
			continue
		fi

		# We don't care about the date in the index
		index="$( rev <<<"${index}" | cut -d"." -f 4- | rev )"

		for kibana_pod in $( oc get pods --selector component="${OAL_KIBANA_COMPONENT}"  -o jsonpath='{ .items[*].metadata.name }' ); do
			os::log::info "Checking for index ${index} with Kibana pod ${kibana_pod}..."
			# As we're checking system log files, we need to use `sudo`
			os::cmd::expect_success "sudo -E VERBOSE=true go run '${OS_O_A_L_DIR}/hack/testing/check-logs.go' '${kibana_pod}' '${elasticsearch_api}' '${index}' '${index_search_path}' '${query_size}' '${test_user}' '${test_token}' '${test_ip}'"
		done
	done

	os::log::info "Checking that Elasticsearch pod ${elasticsearch_pod} contains common data model index templates..."
	os::cmd::expect_success "oc exec ${elasticsearch_pod} -- ls -1 /usr/share/java/elasticsearch/index_templates"
	for template in $( oc exec "${elasticsearch_pod}" -- ls -1 /usr/share/java/elasticsearch/index_templates ); do
		os::cmd::expect_success_and_text "curl_es '${elasticsearch_pod}' '/_template/${template}' --request HEAD --head --output /dev/null --write-out '%{response_code}'" '200'
	done

	os::log::debug "Checking that Elasticsearch pod ${elasticsearch_pod} has expected plugins installed"
	curl_es "${elasticsearch_pod}" '/_cat/plugins?local=true&v'
	matching_plugins=0
	found_plugins=$( curl_es "${elasticsearch_pod}" '/_cat/plugins?local=true&h=component' )
	for plugin in $found_plugins[@] ; do
		os::log::info "Installed plugin: ${plugin}"
		if [ "${plugin}" = "cloud-kubernetes" ]; then
			(( matching_plugins+=1 ))
		elif [ "${plugin}" = "openshift-elasticsearch" ]; then
			(( matching_plugins+=1 ))
		elif [ "${plugin}" = "prometheus-exporter" ]; then
			(( matching_plugins+=1 ))
		fi
	done
	if [ "$matching_plugins" -lt "3" ]; then
		os::log::fatal "Elasticsearch pod is missing expected plugin(s). Exp cloud-kubernetes, openshift-elasticsearch, prometheus-exporter, found: ${found_plugins[*]}"
	else
		os::log::info "Elasticsearch pod ${elasticsearch_pod} contains expected plugin(s)"
	fi

#	WIP, uncommented unless we figure out how to get user name
#	os::log::info "Checking that Elasticsearch pod ${elasticsearch_pod} exports Prometheus metrics"
#	user_name="prometheus" #?
#	barer_token="_na_"     #?
#	prometheus_metrics=$( curl_es_with_token "${elasticsearch_pod}" '/_prometheus/metrics' "$user_name" "$barer_token" )

done

os::test::junit::declare_suite_end

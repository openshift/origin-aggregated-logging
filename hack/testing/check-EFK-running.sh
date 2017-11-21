#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}" )/../lib/init.sh"

oal_expected_deploymentconfigs=( "logging-kibana" "logging-curator" )
oal_expected_routes=( "logging-kibana" )
oal_expected_services=( "logging-es" "logging-es-cluster" "logging-kibana" )
oal_expected_oauthclients=( "kibana-proxy" )
oal_expected_daemonsets=( "logging-fluentd" )
oal_elasticseach_components=( "es" )
oal_kibana_components=( "kibana" )

if [ "$1" = "true" ]; then
	# There is an ops cluster set up, so we
	# need to expect to see more objects.
	oal_expected_deploymentconfigs+=( "logging-kibana-ops" "logging-curator-ops" )
	oal_expected_routes+=( "logging-kibana-ops" )
	oal_expected_services+=( "logging-es-ops" "logging-es-ops-cluster" "logging-kibana-ops" )
	oal_elasticseach_components+=( "es-ops" )
	oal_kibana_components+=( "kibana-ops" )
fi

function get_es_dc() {
  # $1 - cluster name postfix
  if [ -z $(oc get dc -l cluster-name=logging-${1},es-node-role=clientdata --no-headers | awk '{print $1}') ] ; then
    oc get deploymentconfigs --namespace logging --selector component=${1} -o jsonpath='{.items[*].metadata.name}' | grep -E "^logging-${1}-(data-)?(master|client)-[a-zA-Z0-9]{8}"
  else
    oc get deploymentconfigs --namespace logging --selector cluster-name=logging-${1},es-node-role=clientdata -o jsonpath='{.items[*].metadata.name}' | grep -E "^logging-${1}-clientdata-[0-9]"
  fi
}

# Currently one DeploymentConfig per Elasticsearch
# replica is created, and is therefore given a long
# unique name that we do not know beforehand. We
# only know that there should be DCs with the
# logging-es- prefix, so we cheat now to look it up
# and keep the cluster rollout test clean.
# TODO: This will not be necessary when StatefulSets
# are used to deploy the cluster instead.
es_dcs="$( get_es_dc es )"
if [[ "$( wc -w <<<"${es_dcs}" )" -ne 1 ]]; then
	os::log::fatal "Expected to find one Elasticsearch DeploymentConfig, got: '${es_dcs:-"<none>"}'"
fi

oal_expected_deploymentconfigs+=( ${es_dcs} )
if [ "$1" = "true" ]; then
	es_ops_dcs="$( get_es_dc es-ops )"
	if [[ "$( wc -w <<<"${es_ops_dcs}" )" -ne 1 ]]; then
		os::log::fatal "Expected to find one OPS Elasticsearch DeploymentConfig, got: '${es_ops_dcs:-"<none>"}'"
	fi
	oal_expected_deploymentconfigs+=( ${es_ops_dcs} )
fi

OAL_EXPECTED_DEPLOYMENTCONFIGS="${oal_expected_deploymentconfigs[*]}" \
OAL_EXPECTED_ROUTES="${oal_expected_routes[*]}"                       \
OAL_EXPECTED_SERVICES="${oal_expected_services[*]}"                   \
OAL_EXPECTED_OAUTHCLIENTS="${oal_expected_oauthclients[*]}"           \
OAL_EXPECTED_DAEMONSETS="${oal_expected_daemonsets[*]}"               \
"${OS_O_A_L_DIR}/test/cluster/rollout.sh"

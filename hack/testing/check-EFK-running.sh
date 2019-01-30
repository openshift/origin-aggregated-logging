#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}" )/../lib/init.sh"

LOGGING_NS=${LOGGING_NS:-openshift-logging}
if oc get clusterlogging > /dev/null 2>&1 ; then
	USE_OPERATOR=${USE_OPERATOR:-true}
else
	USE_OPERATOR=${USE_OPERATOR:-false}
fi

function get_es_dc() {
  # $1 - cluster name postfix
  if [ -z $(oc get dc -l cluster-name=logging-${1},es-node-role=clientdata --no-headers | awk '{print $1}') ] ; then
    oc get deploymentconfigs --namespace ${LOGGING_NS} --selector component=${1} -o jsonpath='{.items[*].metadata.name}' | grep -E "^logging-${1}-(data-)?(master|client)-[a-zA-Z0-9]{8}"
  else
    oc get deploymentconfigs --namespace ${LOGGING_NS} --selector cluster-name=logging-${1},es-node-role=clientdata -o jsonpath='{.items[*].metadata.name}' | grep -E "^logging-${1}-clientdata-[0-9]"
  fi
}

function get_es_deployments() {
    oc -n $LOGGING_NS get deployment -l cluster-name=$1 -o jsonpath='{.items[0].metadata.name}' 2> /dev/null
}

if [ "$USE_OPERATOR" = true ] ; then
	oal_expected_deploymentconfigs=( "" )
	oal_expected_daemonsets=( "fluentd" )
	oal_expected_oauthclients=( "kibana-proxy" )
	if [ "$1" = "true" ]; then
		oal_expected_deployments=( "kibana-app" "kibana-infra" )
		oal_expected_cronjobs=( "curator-app" "curator-infra" )
		oal_expected_routes=( "kibana-app" "kibana-infra" )
		oal_expected_services=( kibana-app kibana-infra elasticsearch-app \
			elasticsearch-app-cluster elasticsearch-infra elasticsearch-infra-cluster )
		esdeploy=$( get_es_deployments elasticsearch-app )
		if [ -z "$esdeploy" ] ; then
			os::log::fatal "No Elasticsearch Deployment elasticsearch-app"
		fi
		oal_expected_deployments+=( $esdeploy )
		esdeploy=$( get_es_deployments elasticsearch-infra )
		if [ -z "$esdeploy" ] ; then
			os::log::fatal "No Elasticsearch Deployment elasticsearch-infra"
		fi
		oal_expected_deployments+=( $esdeploy )
	else
		oal_expected_deployments=( "kibana" )
		oal_expected_cronjobs=( "curator" )
		oal_expected_routes=( "kibana" )
		oal_expected_services=( kibana elasticsearch elasticsearch-cluster )
		esdeploy=$( get_es_deployments elasticsearch )
		if [ -z "$esdeploy" ] ; then
			os::log::fatal "No Elasticsearch Deployment elasticsearch"
		fi
		oal_expected_deployments+=( $esdeploy )
	fi
else
	oal_expected_deployments=( "" )
	oal_expected_deploymentconfigs=( "logging-kibana" )
	oal_expected_cronjobs=( "logging-curator" )
	oal_expected_routes=( "logging-kibana" )
	oal_expected_services=( "logging-es" "logging-es-cluster" "logging-kibana" )
	oal_expected_oauthclients=( "kibana-proxy" )
	oal_expected_daemonsets=( "logging-fluentd" )
	if [ "$1" = "true" ]; then
		# There is an ops cluster set up, so we
		# need to expect to see more objects.
		oal_expected_deploymentconfigs+=( "logging-kibana-ops" )
		oal_expected_cronjobs+=( "logging-curator-ops" )
		oal_expected_routes+=( "logging-kibana-ops" )
		oal_expected_services+=( "logging-es-ops" "logging-es-ops-cluster" "logging-kibana-ops" )
	fi

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
fi

OAL_EXPECTED_DEPLOYMENTS="${oal_expected_deployments[*]}"             \
OAL_EXPECTED_DEPLOYMENTCONFIGS="${oal_expected_deploymentconfigs[*]}" \
OAL_EXPECTED_ROUTES="${oal_expected_routes[*]}"                       \
OAL_EXPECTED_SERVICES="${oal_expected_services[*]}"                   \
OAL_EXPECTED_OAUTHCLIENTS="${oal_expected_oauthclients[*]}"           \
OAL_EXPECTED_DAEMONSETS="${oal_expected_daemonsets[*]}"               \
OAL_EXPECTED_CRONJOBS="${oal_expected_cronjobs[*]}"                   \
"${OS_O_A_L_DIR}/test/cluster/rollout.sh"

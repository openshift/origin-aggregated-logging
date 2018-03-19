#!/bin/bash

# This rollout test ensures that the DeploymentConfigs
# that are specified have been created and deployed
# successfully onto the cluster. This script expects
# the following environment variables:
#
#  - OAL_EXPECTED_{
#                  DEPLOYMENTCONFIGS,
#                  OAUTHCLIENTS,
#                  DAEMONSETS,
#                  SERVICES,
#                  ROUTES
#                  }: $IFS-delimited lists of
#    OpenShift ojects that are expected to exist
source "$(dirname "${BASH_SOURCE[0]}" )/../../hack/lib/init.sh"
trap os::test::junit::reconcile_output EXIT

FLUENTD_WAIT_TIME=$(( 2 * minute ))

os::test::junit::declare_suite_start "test/cluster/rollout"

os::cmd::expect_success "oc project logging"

os::log::info "Checking for DeploymentConfigurations..."
for deploymentconfig in ${OAL_EXPECTED_DEPLOYMENTCONFIGS}; do
	os::cmd::expect_success "oc get deploymentconfig ${deploymentconfig}"

# this is to get around the current kubelet flake where we need to re-rollout to get the dc running
#  for sanity sake and to not get stuck in the case of real issues, we will only do this once per dc
	if ! oc rollout status deploymentconfig/${deploymentconfig} ; then
		os::cmd::expect_success "oc rollout cancel deploymentconfig/${deploymentconfig}"
		os::cmd::expect_success "oc rollout latest ${deploymentconfig}"
		os::cmd::expect_success "oc rollout status deploymentconfig/${deploymentconfig}"
	fi
done

os::log::info "Checking for Routes..."
for route in ${OAL_EXPECTED_ROUTES}; do
	os::cmd::expect_success "oc get route ${route}"
done

os::log::info "Checking for Services..."
for service in ${OAL_EXPECTED_SERVICES}; do
	os::cmd::expect_success "oc get service ${service}"
done

os::log::info "Checking for OAuthClients..."
for oauthclient in ${OAL_EXPECTED_OAUTHCLIENTS}; do
	os::cmd::expect_success "oc get oauthclient ${oauthclient}"
done

os::log::info "Checking for DaemonSets..."
for daemonset in ${OAL_EXPECTED_DAEMONSETS}; do
	os::cmd::expect_success "oc get daemonset ${daemonset}"
	desired_number="$( oc get daemonset "${daemonset}" -o jsonpath='{ .status.desiredNumberScheduled }' )"
	os::cmd::try_until_text "oc get daemonset ${daemonset} -o jsonpath='{ .status.numberReady }'" "${desired_number}" $FLUENTD_WAIT_TIME
done

os::log::info "Checking for CronJobs..."
for cronjob in ${OAL_EXPECTED_CRONJOBS}; do
	os::cmd::expect_success "oc get cronjob ${cronjob}"
done

os::test::junit::declare_suite_end

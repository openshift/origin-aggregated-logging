#!/bin/bash -x

# This rollout test ensures that the DeploymentConfigs
# that are specified have been created and deployed
# successfully onto the cluster. This script expects
# the following environment variables:
#
#  - OAL_EXPECTED_{
#                  DEPLOYMENTCONFIGS,
#                  CRONJOBS,
#                  OAUTHCLIENTS,
#                  DAEMONSETS,
#                  SERVICES,
#                  ROUTES
#                  }: $IFS-delimited lists of
#    OpenShift ojects that are expected to exist
source "$(dirname "${BASH_SOURCE[0]}" )/../../hack/lib/init.sh"

LOGGING_NS=${LOGGING_NS:-openshift-logging}
FLUENTD_WAIT_TIME=$(( 2 * minute ))

cleanup() {
  for r in dc ds cronjob ; do
    oc describe -n ${LOGGING_NS} $r > $ARTIFACT_DIR/$r.describe 2>&1
  done

  for p in $(oc get pods -n ${LOGGING_NS} -l component=es -o jsonpath={.items[*].metadata.name}) ; do
    oc logs -c elasticsearch -n ${LOGGING_NS} $p || :  > $ARTIFACT_DIR/$p.rollout.stdout.logs 2>&1
    oc logs -c proxy -n ${LOGGING_NS} $p > $ARTIFACT_DIR/$p.proxy.stdout.logs 2>&1
    oc exec -c elasticsearch -n ${LOGGING_NS} $p -- logs || :  > $ARTIFACT_DIR/$p.rollout.file.logs 2>&1
  done
  for p in $(oc get pods -n ${LOGGING_NS} -l component!=es -o jsonpath={.items[*].metadata.name}) ; do
    oc logs -n ${LOGGING_NS} $p || :  > $ARTIFACT_DIR/$p.stdout.logs 2>&1
  done
  
  os::test::junit::reconcile_output
}
trap "cleanup" EXIT

os::test::junit::declare_suite_start "test/cluster/rollout"

os::cmd::expect_success "oc project ${LOGGING_NS}"

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

os::log::info "Checking for CronJobs..."
for cronjob in ${OAL_EXPECTED_CRONJOBS}; do
	os::cmd::expect_success "oc get cronjob ${cronjob}"
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

#!/bin/bash

# This rollout test ensures that the DeploymentConfigs
# that are specified have been created and deployed
# successfully onto the cluster. This script expects
# the following environment variables:
#
#  - OAL_EXPECTED_{
#                  DEPLOYMENTCONFIGS,
#                  CRONJOBS,
#                  DAEMONSETS,
#                  SERVICES,
#                  ROUTES
#                  }: $IFS-delimited lists of
#    OpenShift ojects that are expected to exist
source "$(dirname "${BASH_SOURCE[0]}" )/../../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"

LOGGING_NS=${LOGGING_NS:-openshift-logging}
FLUENTD_WAIT_TIME=$(( 2 * minute ))

cleanup() {
  local return_code="$?"
  set +e
  for r in dc ds cronjob deployment ; do
    for it in $( oc get -n ${LOGGING_NS} $r -o jsonpath='{.items[*].metadata.name}' ) ; do
      oc describe -n ${LOGGING_NS} $r $it > $ARTIFACT_DIR/$r.$it.describe 2>&1
      oc get -n ${LOGGING_NS} $r $it -o yaml > $ARTIFACT_DIR/$r.$it.yaml 2>&1
    done
  done

  get_all_logging_pod_logs
  oc get -n ${LOGGING_NS} all --include-uninitialized=true 2>&1 | artifact_out
  oc get -n ${LOGGING_NS} pods -o wide 2>&1 | artifact_out
  if type -p docker > /dev/null 2>&1 ; then
    oal_sudo docker images|grep logging 2>&1 | artifact_out
    oal_sudo docker images|grep oauth 2>&1 | artifact_out
    oal_sudo docker images|grep eventrouter 2>&1 | artifact_out
  fi
  oc get events > $ARTIFACT_DIR/events.txt 2>&1

  os::test::junit::reconcile_output
  exit $return_code
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
		os::cmd::expect_success "oc rollout latest deploymentconfig/${deploymentconfig}"
		os::cmd::expect_success "oc rollout status deploymentconfig/${deploymentconfig}"
	fi
done

os::log::info "Checking for Deployments..."
for deployment in ${OAL_EXPECTED_DEPLOYMENTS}; do
	os::cmd::expect_success "oc get deployment ${deployment}"
  os::cmd::try_until_text "oc rollout status deployment/${deployment}" "successfully rolled out"
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

os::log::info "Checking for DaemonSets..."
for daemonset in ${OAL_EXPECTED_DAEMONSETS}; do
	os::cmd::expect_success "oc get daemonset ${daemonset}"
	desired_number="$( oc get daemonset "${daemonset}" -o jsonpath='{ .status.desiredNumberScheduled }' )"
	os::cmd::try_until_text "oc get daemonset ${daemonset} -o jsonpath='{ .status.numberReady }'" "${desired_number}" $FLUENTD_WAIT_TIME
done

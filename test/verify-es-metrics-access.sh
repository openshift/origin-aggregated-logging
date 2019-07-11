#!/bin/bash

# test access control
source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
trap os::test::junit::reconcile_output EXIT
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/verify-es-metrics-access"

LOGGING_NS=${LOGGING_NS:-openshift-logging}
suffix=$RANDOM
UNAUTHORIZED_SA="unauthorized-sa-${suffix}"
AUTHORIZED_SA="authorized-sa-${suffix}"
CLUSTERROLE="prometheus-k8s-${suffix}"

function cleanup() {
    local result_code="$?"
    set +e
    
    for name in "${UNAUTHORIZED_SA}" "${AUTHORIZED_SA}" ; do
        oc -n ${LOGGING_NS} delete serviceaccount ${name} 2>&1 | artifact_out
    done
    oc -n ${LOGGING_NS} delete rolebinding metrics-test-reader-${suffix} 2>&1 | artifact_out
    oc delete clusterrole ${CLUSTERROLE} 2>&1 | artifact_out
    oc delete clusterrolebinding ${CLUSTERROLE} 2>&1 | artifact_out
    oc delete clusterrolebinding view-${CLUSTERROLE} 2>&1 | artifact_out

    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $result_code
}
trap cleanup EXIT

oc login --username=system:admin > /dev/null

os::log::info Creating serviceaccounts to verify metrics
os::cmd::expect_success "oc -n ${LOGGING_NS} create serviceaccount ${UNAUTHORIZED_SA}"
os::cmd::expect_success "oc -n ${LOGGING_NS} create serviceaccount ${AUTHORIZED_SA}"

result=$(oc get clusterrole ${CLUSTERROLE} --ignore-not-found ||:)
if [ "$result" == "" ] ; then
  os::cmd::expect_success "echo '{\"apiVersion\":\"rbac.authorization.k8s.io/v1\", \"kind\":\"ClusterRole\",\"metadata\":{\"name\":\"${CLUSTERROLE}\"},\"rules\":[{\"nonResourceURLs\":[\"/metrics\"],\"verbs\":[\"get\"]}]}' | oc create -f -"
fi
result=$(oc get clusterrolebinding ${CLUSTERROLE} --ignore-not-found ||:)
if [ "$result" == "" ] ; then
  os::log::info Binding ${AUTHORIZED_SA} to be cable of reading metrics
  os::cmd::expect_success "oc create clusterrolebinding --clusterrole=${CLUSTERROLE} ${CLUSTERROLE} --serviceaccount=${LOGGING_NS}:${AUTHORIZED_SA}"
fi
result=$(oc get clusterrolebinding view-${CLUSTERROLE} --ignore-not-found ||:)
if [ "$result" == "" ] ; then
  os::log::info Binding ${AUTHORIZED_SA} to be cable of getting namespaces
  os::cmd::expect_success "oc create clusterrolebinding --clusterrole=view view-${CLUSTERROLE} --serviceaccount=${LOGGING_NS}:${AUTHORIZED_SA}"
fi

service_ip=$(oc -n ${LOGGING_NS} get service elasticsearch-metrics -o jsonpath={.spec.clusterIP})

os::log::info Checking ${UNAUTHORIZED_SA} ability to read metrics through metrics service
os::cmd::expect_success_and_text "curl -kv https://${service_ip}:60000/_prometheus/metrics -H\"Authorization: Bearer $(oc serviceaccounts get-token $UNAUTHORIZED_SA)\" -w '%{response_code}\n'" '403$'

os::log::info Checking ${AUTHORIZED_SA} ability to read metrics
if os::cmd::expect_success_and_text "curl -kv https://${service_ip}:60000/_prometheus/metrics -H\"Authorization: Bearer $(oc serviceaccounts get-token $AUTHORIZED_SA)\" -w '%{response_code}\n'" '200$' ; then
    os::log::info "Received data from metrics endpoint"
else
	artifact_log unable to connect to prometheus end point through service:
	os::log::fatal "Failed while curling _prometheus/metrics endpoint"
fi

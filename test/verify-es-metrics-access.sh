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

function cleanup() {
    local result_code="$?"
    set +e
    
    for name in "${UNAUTHORIZED_SA}" "${AUTHORIZED_SA}" ; do
        oc -n ${LOGGING_NS} delete serviceaccount ${name} 2>&1 | artifact_out
    done
    oc -n ${LOGGING_NS} delete rolebinding metrics-test-reader-${suffix} 2>&1 | artifact_out

    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $result_code
}
trap cleanup EXIT

oc login --username=system:admin > /dev/null

os::log::info Creating serviceaccounts to verify metrics
os::cmd::expect_success "oc -n ${LOGGING_NS} create serviceaccount ${UNAUTHORIZED_SA}"
os::cmd::expect_success "oc -n ${LOGGING_NS} create serviceaccount ${AUTHORIZED_SA}"

os::log::info Binding ${AUTHORIZED_SA} to be cable of reading metrics
os::cmd::expect_success "oc create rolebinding --role=prometheus-metrics-viewer metrics-test-reader-${suffix} --serviceaccount=${LOGGING_NS}:${AUTHORIZED_SA}"

service_ip=$(oc -n ${LOGGING_NS} get service logging-es-prometheus -o jsonpath={.spec.clusterIP})

os::log::info Checking ${UNAUTHORIZED_SA} ability to read metrics
os::cmd::expect_success_and_text "curl -kv https://${service_ip}/_prometheus/metrics -H\"Authorization: Bearer $(oc serviceaccounts get-token $UNAUTHORIZED_SA)\" -w '%{response_code}\n'" '403$'

os::log::info Checking ${AUTHORIZED_SA} ability to read metrics
os::cmd::expect_success_and_text "curl -kv https://${service_ip}/_prometheus/metrics -H\"Authorization: Bearer $(oc serviceaccounts get-token $AUTHORIZED_SA)\" -w '%{response_code}\n'" '200$'

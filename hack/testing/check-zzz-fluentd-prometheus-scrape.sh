#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}" )/../lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"

os::test::junit::declare_suite_start "test/check-zzz-fluentd-prometheus-scrape"

cleanup() {
    local return_code="$?"
    set +e

    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

LOGGING_NS=${LOGGING_NS:-openshift-logging}

fpod="$(get_running_pod fluentd)"
fpod_ip="$(oc get pod ${fpod} -o jsonpath='{.status.podIP}')"

os::cmd::expect_success "curl -k https://${fpod_ip}:24231/metrics"
curl -k https://${fpod_ip}:24231/metrics >> $ARTIFACT_DIR/${fpod}-metrics-scrape 2>&1 || :

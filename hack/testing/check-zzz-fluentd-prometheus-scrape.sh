#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}" )/../lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"

test_name=check-zzz-fluentd-prometheus-scrape
os::test::junit::declare_suite_start "test/$test_name"

cleanup() {
    local return_code="$?"
    set +e
    mkdir -p $ARTIFACT_DIR/$test_name
    oc -n $LOGGING_NS get configmap fluentd -o jsonpath={.data} > $ARTIFACT_DIR/$test_name/fluent-configmap.log
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

LOGGING_NS=${LOGGING_NS:-openshift-logging}

fpod=$(oc -n $LOGGING_NS get pod -l component=fluentd -o jsonpath={.items[0].metadata.name})

os::cmd::try_until_success "oc -n $LOGGING_NS exec $fpod -- curl -ks https://localhost:24231/metrics" "$(( 2 * minute ))"
os::cmd::try_until_success "oc -n $LOGGING_NS exec $fpod -- curl -ks https://fluentd.openshift-logging.svc:24231/metrics" "$(( 2 * minute ))"

fpod_ip="$(oc  -n $LOGGING_NS get pod ${fpod} -o jsonpath='{.status.podIP}')"
os::cmd::try_until_success "oc -n $LOGGING_NS exec $fpod -- curl -ks https://${fpod_ip}:24231/metrics" "$(( 2 * minute ))"

oc -n $LOGGING_NS exec $fpod -- curl -kq https://${fpod_ip}:24231/metrics >> $ARTIFACT_DIR/${fpod}-metrics-scrape 2>&1 || :

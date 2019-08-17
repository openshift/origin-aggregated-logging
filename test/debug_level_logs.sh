#!/bin/bash

# This is a test suite for the debug_level_logs

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::test::junit::declare_suite_start "test/debug_level_logs"

cleanup() {
    local return_code="$?"
    set +e

    stop_fluentd $fpod 2>&1 | artifact_out
    oc set env ds/logging-fluentd COLLECT_JOURNAL_DEBUG_LOGS- 2>&1 | artifact_out
    start_fluentd true 2>&1 | artifact_out

    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

stop_fluentd 2>&1 | artifact_out
oc set env ds/logging-fluentd COLLECT_JOURNAL_DEBUG_LOGS=true 2>&1 | artifact_out
start_fluentd true 2>&1 | artifact_out

get_logmessage2() {
    logmessage2="$1"
    cp "$2" $ARTIFACT_DIR/debug_level_logs-ops.json
}

TEST_REC_PRIORITY=debug wait_for_fluentd_to_catch_up '' get_logmessage2
os::cmd::expect_success "cat $ARTIFACT_DIR/debug_level_logs-ops.json | jq '.hits.hits[0]._source.level == \"debug\"'"

#!/bin/bash

# This is a test suite for the debug_level_logs

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::test::junit::declare_suite_start "test/debug_level_logs"

get_logmessage() {
    logmessage="$1"
}
get_logmessage2() {
    logmessage2="$1"
}

es_pod=$( get_es_pod es )
es_ops_pod=$( get_es_pod es-ops )
es_ops_pod=${es_ops_pod:-$es_pod}

TEST_REC_PRIORITY=debug wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${logmessage2}"'"}}}'
os::cmd::expect_success "curl_es ${es_ops_pod} /.operations.*/_count -X POST -d '$qs' | jq '.count > 0'"

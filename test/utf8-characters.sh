#!/bin/bash

# This logging test ensures that a log message containing
# extended UTF-8 characters will be correctly processed by
# Fluentd and appear in Elasticsearch.

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/utf8-characters"

if [ -n "${DEBUG:-}" ] ; then
    set -x
fi

cleanup() {
    local return_code="$?"
    set +e
    if [ $return_code = 0 ] ; then
        mycmd=os::log::info
    else
        mycmd=os::log::error
    fi
    $mycmd "utf8-characters test finished at $( date )"
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

os::log::info "Starting utf8-characters test at $( date )"

wait_for_fluentd_ready

message_uuid="$( uuidgen )"
message="$(printf '%s-\xC2\xB5' "$message_uuid" )"
logger -p local6.info -t "$message_uuid" "$message"

es_ops_pod="$( get_es_pod es-ops )"
if [ -z "$es_ops_pod" ] ; then
    es_ops_pod="$( get_es_pod es )"
fi
qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${message_uuid}"'"}}}'
os::cmd::try_until_text "curl_es ${es_ops_pod} /.operations.*/_count -X POST -d '$qs' | get_count_from_json" 1 $(( 300 * second ))
os::log::info "Checking that message was successfully processed..."
os::cmd::expect_success "curl_es $es_ops_pod /.operations.*/_search -X POST -d '$qs' | \
                         python $OS_O_A_L_DIR/hack/testing/test-utf8-characters.py '$message' $message_uuid"

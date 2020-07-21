#!/bin/bash

# test that logging will parse the message field containing
# embedded JSON into its component fields, and use the
# original message field in the embedded JSON

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/json-parsing"

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
    $mycmd json-parsing test finished at $( date )
    fpod=$( get_running_pod fluentd )
    if [ -n "${fpod:-}" ] ; then
        get_fluentd_pod_log > $ARTIFACT_DIR/json-parsing-fluentd-pod.log
    fi
    if [ "${orig_MERGE_JSON_LOG:-}" = unset ] ; then
        orig_MERGE_JSON_LOG="MERGE_JSON_LOG-"
    fi
    if [ "${orig_CDM_UNDEFINED_TO_STRING:-}" = unset ] ; then
        orig_CDM_UNDEFINED_TO_STRING="CDM_UNDEFINED_TO_STRING-"
    fi
    if [ -n "${orig_MERGE_JSON_LOG:-}" -o -n "${orig_CDM_UNDEFINED_TO_STRING:-}" ] ; then
        stop_fluentd
        oc set env $fluentd_ds ${orig_MERGE_JSON_LOG:-} ${orig_CDM_UNDEFINED_TO_STRING:-}
        start_fluentd
    fi
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

os::log::info Starting json-parsing test at $( date )

# enable merge json log
orig_MERGE_JSON_LOG=$( oc set env $fluentd_ds --list | grep \^MERGE_JSON_LOG= ) || :
if [ -z "$orig_MERGE_JSON_LOG" ] ; then
    orig_MERGE_JSON_LOG=unset
fi
orig_CDM_UNDEFINED_TO_STRING=$( oc set env $fluentd_ds --list | grep \^CDM_UNDEFINED_TO_STRING= ) || :
if [ -z "$orig_CDM_UNDEFINED_TO_STRING" ] ; then
    orig_CDM_UNDEFINED_TO_STRING=unset
fi
stop_fluentd
oc set env $fluentd_ds MERGE_JSON_LOG=true CDM_UNDEFINED_TO_STRING=false
start_fluentd

# generate a log message in the Kibana logs - Kibana log messages are in JSON format:
# {"type":"response","@timestamp":"2017-04-07T02:03:37Z","tags":[],"pid":1,"method":"get","statusCode":404,"req":{"url":"/ca30cead-d470-4db8-a2a2-bb71439987e2","method":"get","headers":{"user-agent":"curl/7.29.0","host":"localhost:5601","accept":"*/*"},"remoteAddress":"127.0.0.1","userAgent":"127.0.0.1"},"res":{"statusCode":404,"responseTime":3,"contentLength":9},"message":"GET /ca30cead-d470-4db8-a2a2-bb71439987e2 404 3ms - 9.0B"}
# logging should parse this and make "type", "tags", "statusCode", etc. as top level fields
# the "message" field should contain only the embedded message and not the entire JSON blob

get_record() {
    json_test_uuid=$1
    cp $2 $ARTIFACT_DIR/json-parsing-output.json
}
wait_for_fluentd_to_catch_up get_record

os::log::info Testing if record is in correct format . . .
os::cmd::expect_success "cat $ARTIFACT_DIR/json-parsing-output.json | \
                         python $OS_O_A_L_DIR/hack/testing/test-json-parsing.py $json_test_uuid"

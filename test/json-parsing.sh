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

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 2 * minute ))}

stop_fluentd() {
  artifact_log at this point there should be 1 fluentd running in Running state
  oc get pods 2>&1 | artifact_out
  local fpod=$( get_running_pod fluentd )
  oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
  os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
  artifact_log at this point there should be no fluentd running - number ready is 0
  oc get pods 2>&1 | artifact_out
  # for some reason, in this test, after .status.numberReady is 0, the fluentd pod hangs around
  # in the Terminating state for many seconds, which seems to cause problems with subsequent tests
  # so, we have to wait for the pod to completely disappear - we cannot rely on .status.numberReady == 0
  if [ -n "${fpod:-}" ] ; then
    os::cmd::try_until_failure "oc get pod $fpod > /dev/null 2>&1" $FLUENTD_WAIT_TIME
  fi
}

start_fluentd() {
  sudo rm -f /var/log/fluentd/fluentd.log
  oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
  os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running " $FLUENTD_WAIT_TIME
}

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

    sudo ls -alrtF /var/lib/fluentd 2>&1 | artifact_out
    sudo docker info | grep -i log 2>&1 | artifact_out
    sudo ls -alrtF /var/log/containers 2>&1 | artifact_out

    stop_fluentd
    if [ "${orig_MERGE_JSON_LOG:-}" = unset ] ; then
        orig_MERGE_JSON_LOG="MERGE_JSON_LOG-"
    fi
    if [ "${orig_CDM_UNDEFINED_TO_STRING:-}" = unset ] ; then
        orig_CDM_UNDEFINED_TO_STRING="CDM_UNDEFINED_TO_STRING-"
    fi
    if [ -n "${orig_MERGE_JSON_LOG:-}" -o -n "${orig_CDM_UNDEFINED_TO_STRING:-}" ] ; then
        stop_fluentd
        oc set env daemonset/logging-fluentd ${orig_MERGE_JSON_LOG:-} ${orig_CDM_UNDEFINED_TO_STRING:-}
        start_fluentd
    fi


    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

os::log::info Starting json-parsing test at $( date )

# enable merge json log
orig_MERGE_JSON_LOG=$( oc set env daemonset/logging-fluentd --list | grep \^MERGE_JSON_LOG= ) || :
if [ -z "$orig_MERGE_JSON_LOG" ] ; then
    orig_MERGE_JSON_LOG=unset
fi
orig_CDM_UNDEFINED_TO_STRING=$( oc set env daemonset/logging-fluentd --list | grep \^CDM_UNDEFINED_TO_STRING= ) || :
if [ -z "$orig_CDM_UNDEFINED_TO_STRING" ] ; then
    orig_CDM_UNDEFINED_TO_STRING=unset
fi
stop_fluentd
oc set env daemonset/logging-fluentd MERGE_JSON_LOG=true CDM_UNDEFINED_TO_STRING=false
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

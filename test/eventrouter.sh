#!/bin/bash

# This is a test suite for the eventrouter

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::test::junit::declare_suite_start "test/eventrouter"

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 3 * minute ))}

muxmode=$( oc set env ds/logging-fluentd --list | grep \^MUX_CLIENT_MODE ) || :
if [ -z "${muxmode:-}" ] ; then
    muxmode=MUX_CLIENT_MODE-
fi

cleanup() {
    local return_code="$?"
    set +e
    fpod=$( get_running_pod fluentd )
    oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
    if [ -n "${fpod:-}" ] ; then
        os::cmd::try_until_failure "oc get pod $fpod > /dev/null 2>&1" $FLUENTD_WAIT_TIME
    fi
    oc set env ds/logging-fluentd $muxmode
    oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running " $FLUENTD_WAIT_TIME
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

function warn_nonformatted() {
    local es_svc=$1
    local index=$2
    # check if eventrouter and fluentd with correct ViaQ plugin are deployed
    local non_formatted_event_count=$( curl_es $es_svc /$index/_count?q=verb:* | get_count_from_json )
    if [ "$non_formatted_event_count" != 0 ]; then
        os::log::warning "$non_formatted_event_count events from eventrouter in index $index were not processed by ViaQ fluentd plugin"
    fi
}
function get_eventrouter_pod() {
    oc get pods --namespace=default -l component=eventrouter --no-headers | awk '$3 == "Running" {print $1}'
}

function logs_count_is_gt() {
    local expected="$1"
    local myqs="$2"
    local actual=$( curl_es $esopssvc /.operations.*/_count -X POST -d "$myqs" | get_count_from_json )
    echo "logs_count_is_gt: $myqs $actual gt $expected ?" | artifact_out
    test $actual -gt $expected
}

evpod=$( get_eventrouter_pod )
if [ -z "$evpod" ]; then
    os::log::warning "Eventrouter not deployed"
else
    essvc=$( get_es_svc es )
    esopssvc=$( get_es_svc es-ops )
    esopssvc=${esopssvc:-$essvc}

    # Make sure there's no MUX
    # undeploy fluentd
    oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
    oc set env ds/logging-fluentd MUX_CLIENT_MODE- 2>&1 | artifact_out
    oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    warn_nonformatted $essvc '/project.*'
    warn_nonformatted $esopssvc '/.operations.*'

    qs='{"query":{"wildcard":{"kubernetes.event.verb":"*"}}}'
    os::cmd::try_until_success "logs_count_is_gt 0 '$qs'" $FLUENTD_WAIT_TIME
    prev_event_count=$( curl_es $esopssvc /.operations.*/_count -X POST -d "$qs" | get_count_from_json )
    echo "prev_event_count: $prev_event_count $qs $prev_event_count" | artifact_out
    fpod=$( get_running_pod fluentd )

    # utilize mux if mux pod exists
    if oc get dc/logging-mux > /dev/null 2>&1 ; then
        # MUX_CLIENT_MODE: maximal; oc set env restarts logging-fluentd
        oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
        os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
        oc set env ds/logging-fluentd MUX_CLIENT_MODE=maximal 2>&1 | artifact_out
        oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
        os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running " $FLUENTD_WAIT_TIME
        os::cmd::try_until_success "logs_count_is_gt $prev_event_count '$qs'" $FLUENTD_WAIT_TIME
        prev_event_count=$( curl_es $esopssvc /.operations.*/_count -X POST -d "$qs" | get_count_from_json )

        # MUX_CLIENT_MODE: minimal; oc set env restarts logging-fluentd
        oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
        os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
        oc set env ds/logging-fluentd MUX_CLIENT_MODE=minimal 2>&1 | artifact_out
        oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
        os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running " $FLUENTD_WAIT_TIME
        os::cmd::try_until_success "logs_count_is_gt $prev_event_count '$qs'" $FLUENTD_WAIT_TIME
    fi

    # Check if there's no duplicates
    qs='{"query":{"bool":{"must":[{"match_phrase":{"kubernetes.event.verb":"ADDED"}},{"match":{"message":"'"${fpod}"'"}}]}},"_source":["kubernetes.event.metadata.uid","message"]}'
    echo "$fpod" | artifact_out
    echo "$qs" | artifact_out
    os::cmd::try_until_success "logs_count_is_gt 0 '$qs'" $FLUENTD_WAIT_TIME
    curl_es $esopssvc /.operations.*/_search -X POST -d "$qs" | python -mjson.tool | artifact_out
    ids=$( curl_es $esopssvc /.operations.*/_search -X POST -d "$qs" | python -mjson.tool | egrep uid | awk '{print $2}' | sed -e "s/\"//g" )
    for id in $ids; do
      qs='{"query":{"match_phrase":{"kubernetes.event.metadata.uid":"'"${id}"'"}}}'
      artifact_log "$id search ----------------------"
      curl_es $esopssvc /.operations.*/_search -X POST -d "$qs" | python -mjson.tool | artifact_out
      artifact_log "$id count ----------------------"
      curl_es $esopssvc /.operations.*/_count -X POST -d "$qs" | get_count_from_json | artifact_out
      os::cmd::expect_success_and_text "curl_es $esopssvc /.operations.*/_count -X POST -d '$qs' | get_count_from_json" "^1\$"
    done
fi

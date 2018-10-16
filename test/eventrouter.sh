#!/bin/bash

# This is a test suite for the eventrouter

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::test::junit::declare_suite_start "test/eventrouter"

cleanup() {
    local return_code="$?"
    set +e
    if [ -n "${muxmode:-}" ] ; then
        fpod=$( get_running_pod fluentd )
        oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
        os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0"
        os::cmd::try_until_failure "oc get pod $fpod > /dev/null 2>&1"
        oc set env ds/logging-fluentd $muxmode
        oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
        os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    fi
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

function warn_nonformatted() {
    local es_pod=$1
    local index=$2
    # check if eventrouter and fluentd with correct ViaQ plugin are deployed
    local non_formatted_event_count=$( curl_es $es_pod /$index/_count?q=verb:* | get_count_from_json )
    if [ "$non_formatted_event_count" != 0 ]; then
        os::log::warning "$non_formatted_event_count events from eventrouter in index $index were not processed by ViaQ fluentd plugin"
    fi
}
function get_eventrouter_pod() {
    oc get pods --namespace=default -l component=eventrouter --no-headers | awk '$3 == "Running" {print $1}' 
}

evpod=$( get_eventrouter_pod )
if [ -z "$evpod" ]; then
    os::log::warning "Eventrouter not deployed"
else
    # eventrouter does not work with mux in 3.7 - turn it off
    muxmode=$( oc set env ds/logging-fluentd --list | grep \^MUX_CLIENT_MODE ) || :
    if [ -n "$muxmode" ] ; then
        fpod=$( get_running_pod fluentd )
        oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
        os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0"
        os::cmd::try_until_failure "oc get pod $fpod > /dev/null 2>&1"
        oc set env ds/logging-fluentd MUX_CLIENT_MODE-
        oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
        os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
        fpod=$( get_running_pod fluentd )
        # give fluentd a little while to process eventrouter records
        os::log::info Waiting for eventrouter records to be stored in Elasticsearch . . .
        sleep 30
    fi
    espod=$( get_es_pod es )
    esopspod=$( get_es_pod es-ops )
    esopspod=${esopspod:-$espod}

    warn_nonformatted $espod '/project.*'
    warn_nonformatted $esopspod '/.operations.*/'

    os::cmd::try_until_not_text "curl_es $esopspod /.operations.*/_count?q=kubernetes.event.verb:* | get_count_from_json" "^0\$"
fi

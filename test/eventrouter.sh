#!/bin/bash

# This is a test suite for the eventrouter

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"

function get_eventrouter_pod() {
    oc get pods --namespace=default -l component=eventrouter --no-headers | awk '$3 == "Running" {print $1}'
}
evpod=$( get_eventrouter_pod )
if [ -z "$evpod" ]; then
    os::log::warning "Eventrouter not deployed"
    exit 0
fi

os::test::junit::declare_suite_start "test/eventrouter"

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 3 * minute ))}

muxmode=$( oc set env $fluentd_ds --list | grep \^MUX_CLIENT_MODE ) || :
if [ -z "${muxmode:-}" ] ; then
    muxmode=MUX_CLIENT_MODE-
fi

cleanup() {
    local return_code="$?"
    set +e
    stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out
    oc set env $fluentd_ds $muxmode 2>&1 | artifact_out
    start_fluentd false $FLUENTD_WAIT_TIME 2>&1 | artifact_out
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

function warn_nonformatted() {
    local es_svc=$1
    local index=$2
    # check if eventrouter and fluentd with correct ViaQ plugin are deployed
    local non_formatted_event_count=$( curl_es $es_svc $index/_count?q=verb:* | get_count_from_json )
    if [ "$non_formatted_event_count" != 0 ]; then
        os::log::warning "$non_formatted_event_count events from eventrouter in index $index were not processed by ViaQ fluentd plugin"
    fi
}

function logs_count_is_gt() {
    local expected=$1
    local actual=$( curl_es $esopssvc /.operations.*/_count?q=kubernetes.event.verb:* | get_count_from_json )
    test $actual -gt $expected
}

essvc=$( get_es_svc es )
esopssvc=$( get_es_svc es-ops )
esopssvc=${esopssvc:-$essvc}

# Make sure there's no MUX
# undeploy fluentd
stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out
oc set env $fluentd_ds MUX_CLIENT_MODE- 2>&1 | artifact_out
start_fluentd false 2>&1 | artifact_out

warn_nonformatted $essvc '/project.*'
warn_nonformatted $esopssvc '/.operations.*'

os::cmd::try_until_not_text "curl_es $esopssvc /.operations.*/_count?q=kubernetes.event.verb:* | get_count_from_json" "^0\$" $FLUENTD_WAIT_TIME
prev_event_count=$( curl_es $esopssvc /.operations.*/_count?q=kubernetes.event.verb:* | get_count_from_json )

# utilize mux if mux pod exists
if oc get dc/logging-mux > /dev/null 2>&1 ; then
    # MUX_CLIENT_MODE: maximal
    stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out
    oc set env $fluentd_ds MUX_CLIENT_MODE=maximal 2>&1 | artifact_out
    start_fluentd false $FLUENTD_WAIT_TIME 2>&1 | artifact_out
    os::cmd::try_until_success "logs_count_is_gt $prev_event_count" $FLUENTD_WAIT_TIME
    prev_event_count=$( curl_es $esopssvc /.operations.*/_count?q=kubernetes.event.verb:* | get_count_from_json )

    # MUX_CLIENT_MODE: minimal
    stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out
    oc set env $fluentd_ds MUX_CLIENT_MODE=minimal 2>&1 | artifact_out
    start_fluentd false $FLUENTD_WAIT_TIME 2>&1 | artifact_out
    os::cmd::try_until_success "logs_count_is_gt $prev_event_count" $FLUENTD_WAIT_TIME
fi

# Check if there's no duplicates
fpod=$( get_running_pod fluentd )
qs='{"query":{ "bool": { "must": [ {"term":{"kubernetes.event.verb":"ADDED"}}, {"match":{"message":"'"${fpod}"'"}} ] } }, "_source": ["kubernetes.event.metadata.uid", "message"] }'
ids=$( curl_es $esopssvc /.operations.*/_search -X POST -d "$qs" | python -mjson.tool | egrep uid | awk '{print $2}' | sed -e "s/\"//g" )
for id in $ids; do
    os::cmd::expect_success_and_text "curl_es $esopssvc /.operations.*/_count?q=kubernetes.event.metadata.uid:$id | get_count_from_json" "^1\$"
done

#!/bin/bash

# This is a test suite for the fluentd multiline aggregation feature

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 2 * minute ))}

os::test::junit::declare_suite_start "test/multiline"

update_current_fluentd() {
    # undeploy fluentd
    os::log::debug "$( oc label node --all logging-infra-fluentd- )"
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

    # update configmap logging-fluentd
    mconf="$(dirname "${BASH_SOURCE[0]}" )/../hack/testing/filter-events-multiline-test.conf"
    oc get configmap/logging-fluentd -o yaml | sed "/^data:\$/ r $mconf" | oc replace -f -

    # redeploy fluentd
    os::cmd::expect_success flush_fluentd_pos_files
    os::log::debug "$( oc label node --all logging-infra-fluentd=true )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    fpod=$( get_running_pod fluentd ) || :
    artifact_log update_current_fluentd "(oc logs $fpod)"
}

create_test_multiline() {
  oc apply -f $OS_O_A_L_DIR/hack/templates/fluentd-test-multiline.yml
  # wait for the test container to start
  os::cmd::try_until_text "oc get pods -l component=fluentdtestmultiline" "^fluentdtestmultiline-.* Running " 360000
  POD=$( oc get pods -l component=fluentdtestmultiline -o name )
  artifact_log create_test_multiline "(oc logs $POD)"
  oc logs $POD 2>&1 | artifact_out || :
}

# save current fluentd daemonset
saveds=$( mktemp )
oc get daemonset logging-fluentd -o yaml > $saveds

# save current fluentd configmap
savecm=$( mktemp )
oc get configmap logging-fluentd -o yaml > $savecm

cleanup() {
    local return_code="$?"
    set +e
    if [ $return_code = 0 ] ; then
        mycmd=os::log::info
    else
        mycmd=os::log::error
    fi

    # dump the pod before we restart it
    if [ -n "${fpod:-}" ] ; then
        artifact_log cleanup "(oc logs $fpod)"
        oc logs $fpod 2>&1 | artifact_out || :
    fi
    oc get pods 2>&1 | artifact_out

    POD=$( oc get pods -l component=fluentd -o name ) || :
    artifact_log cleanup "(oc logs $POD)"
    oc logs $POD 2>&1 | artifact_out || :

    os::log::debug "$( oc label node --all logging-infra-fluentd- 2>&1 || : )"
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
    if [ -n "${savecm:-}" -a -f "${savecm:-}" ] ; then
        os::log::debug "$( oc replace --force -f $savecm )"
    fi
    if [ -n "${saveds:-}" -a -f "${saveds:-}" ] ; then
        os::log::debug "$( oc replace --force -f $saveds )"
    fi

    $mycmd multiline test finished at $( date )

    os::log::debug "$( oc delete deploymentconfig/fluentd-test-multiline 2>&1 || : )"

    os::log::debug "$( oc label node --all logging-infra-fluentd=true 2>&1 || : )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    fpod=$( get_running_pod fluentd )
    os::cmd::expect_success wait_for_fluentd_to_catch_up
    os::cmd::expect_success flush_fluentd_pos_files
}
trap "cleanup" EXIT

os::log::info Starting multiline test at $( date )

# make sure fluentd is working normally
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
os::cmd::expect_success wait_for_fluentd_to_catch_up

update_current_fluentd
wait_for_fluentd_ready

create_test_multiline

es_ops_svc="$( get_es_svc es-ops )"
if [ -z "$es_ops_svc" ] ; then
    es_ops_svc="$( get_es_svc es )"
fi
qs='{"query":{"term":{"kubernetes.container_name":"fluentdtestmultiline"}}}'
os::cmd::try_until_text "curl_es ${es_ops_svc} /project.*/_count -X POST -d '$qs' | get_count_from_json" 2 $(( 300 * second ))
os::log::info "Checking that the messages were successfully processed..."
os::cmd::expect_success "curl_es $es_ops_svc /project.*/_search -X POST -d '$qs' | \
                         python $OS_O_A_L_DIR/hack/testing/test-multiline.py '$message' $message_uuid"

#!/bin/bash

# test fluentd json-file read throttling
source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"

# does not work with the journald log driver
if docker_uses_journal ; then
    os::log::info This test only works with the json-file docker log driver
    exit 0
fi

trap os::test::junit::reconcile_output EXIT
os::util::environment::use_sudo

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 2 * minute ))}

os::test::junit::declare_suite_start "test/read-throttling"

# save current fluentd daemonset
saveds=$( mktemp )
oc get daemonset logging-fluentd -o yaml > $saveds

# save current fluentd configmap
savecm=$( mktemp )
oc get configmap logging-fluentd -o yaml > $savecm

cleanup() {
    local return_code="$?"
    set +e

    # dump the pod before we restart it
    if [ -n "${fpod:-}" ] ; then
        oc logs $fpod > $ARTIFACT_DIR/$fpod.log 2>&1
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd- 2>&1 || : )"
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
    if [ -n "${savecm:-}" -a -f "${savecm:-}" ] ; then
        os::log::debug "$( oc replace --force -f $savecm 2>&1 )"
    fi
    if [ -n "${saveds:-}" -a -f "${saveds:-}" ] ; then
        os::log::debug "$( oc replace --force -f $saveds 2>&1 )"
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd=true 2>&1 || : )"
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

fpod=$( get_running_pod fluentd )

# generate throttle config with invalid YAML
os::log::debug "$( oc label node --all logging-infra-fluentd- 2>&1 || : )"
os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
os::log::debug "$( oc patch configmap/logging-fluentd --type=json \
   --patch '[{ "op": "replace", "path": "/data/throttle-config.yaml", "value": "\
    test-proj: read_lines_limit: bogus-value"}]' )"
os::log::debug "$( oc label node --all logging-infra-fluentd=true 2>&1 || : )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
# should have fluentd log messages like this
os::cmd::expect_success_and_text "oc logs $fpod" "Could not parse YAML file"

# generate throttle config with a bogus key - verify the correct error
os::log::debug "$( oc label node --all logging-infra-fluentd- 2>&1 || : )"
os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
os::log::debug "$( oc patch configmap/logging-fluentd --type=json \
   --patch '[{ "op": "replace", "path": "/data/throttle-config.yaml", "value": "\
    test-proj:\n  read_lines_limit: bogus-value\nbogus-project:\n  bogus-key: bogus-value"}]' )"
os::log::debug "$( oc label node --all logging-infra-fluentd=true 2>&1 || : )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
# should have fluentd log messages like this
os::cmd::expect_success_and_text "oc logs $fpod" 'Unknown option "bogus-key"'
os::cmd::expect_success_and_text "oc logs $fpod" 'Invalid key/value pair {"bogus-key":"bogus-value"} provided -- ignoring...'
os::cmd::expect_success_and_text "oc logs $fpod" 'Invalid value type matched for "bogus-value"'
os::cmd::expect_success_and_text "oc logs $fpod" 'Invalid key/value pair {"read_lines_limit":"bogus-value"} provided -- ignoring...'

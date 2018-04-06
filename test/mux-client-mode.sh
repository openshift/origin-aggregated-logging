#!/bin/bash

# This is a test suite for the MUX_CLIENT_MODE settings

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

# only works if there is a mux dc
if oc get dc/logging-mux > /dev/null 2>&1 ; then
    oc get dc/logging-mux 2>&1 | artifact_out
else
    oc get dc/logging-mux 2>&1 | artifact_out
    os::log::info dc/logging-mux is not present - skipping test
    exit 0
fi

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 2 * minute ))}

os::test::junit::declare_suite_start "test/mux-client-mode"

# save daemonset
saveds=$( mktemp )
oc get daemonset logging-fluentd -o yaml > $saveds

cleanup() {
    local return_code="$?"
    set +e
    # dump the pods before we restart them
    if [ -n "${fpod:-}" ] ; then
        oc logs $fpod > $ARTIFACT_DIR/mux-client-mode-fluentd-pod.log 2>&1
    fi
    if [ -n "${muxpod:-}" ] ; then
        oc logs $muxpod > $ARTIFACT_DIR/mux-client-mode-mux-pod.log 2>&1
    fi
    if [ -n "${saveds:-}" ] ; then
        if [ -f "${saveds:-}" ]; then
            oc replace --force -f $saveds 2>&1 | artifact_out
            rm -f $saveds
        fi
    fi
    os::cmd::expect_success flush_fluentd_pos_files
    oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

reset_fluentd_daemonset() {
  muxcerts=$( oc get daemonset logging-fluentd -o yaml | egrep muxcerts ) || :

  if [ "$muxcerts" = "" ]; then
      oc set volumes daemonset/logging-fluentd --add --overwrite \
               --name=muxcerts --default-mode=0400 -t secret -m /etc/fluent/muxkeys --secret-name logging-mux 2>&1 | artifact_out
  fi
}

fpod=$( get_running_pod fluentd )
muxpod=$( get_running_pod mux )

os::log::info configure fluentd to use MUX_CLIENT_MODE=minimal - verify logs get through
oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
oc set env daemonset/logging-fluentd MUX_CLIENT_MODE=minimal 2>&1 | artifact_out
reset_fluentd_daemonset
os::cmd::expect_success flush_fluentd_pos_files
oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
wait_for_fluentd_to_catch_up

# configure fluentd to use MUX_CLIENT_MODE=maximal - verify logs get through
os::log::info configure fluentd to use MUX_CLIENT_MODE=maximal - verify logs get through
oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
oc set env daemonset/logging-fluentd MUX_CLIENT_MODE=maximal 2>&1 | artifact_out
reset_fluentd_daemonset
os::cmd::expect_success flush_fluentd_pos_files
oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
wait_for_fluentd_to_catch_up

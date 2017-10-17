#!/bin/bash

# This is a test suite for the MUX_CLIENT_MODE settings

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

# only works if there is a mux dc
if oc get dc/logging-mux > /dev/null 2>&1 ; then
    os::log::debug "$( oc get dc/logging-mux )"
else
    os::log::debug "$( oc get dc/logging-mux )"
    os::log::info dc/logging-mux is not present - skipping test
    exit 0
fi

os::test::junit::declare_suite_start "test/mux-client-mode"

# save daemonset
saveds=$( mktemp )
oc get daemonset logging-fluentd -o yaml > $saveds

cleanup() {
    local return_code="$?"
    set +e
    # dump the pods before we restart them
    if [ -n "${fpod:-}" ] ; then
        oc logs $fpod > $ARTIFACT_DIR/$fpod.log 2>&1
    fi
    if [ -n "${muxpod:-}" ] ; then
        oc logs $muxpod > $ARTIFACT_DIR/$muxpod.log 2>&1
    fi
    if [ -n "${saveds:-}" ] ; then
        if [ -f "${saveds:-}" ]; then
            os::log::debug "$( oc replace --force -f $saveds )"
            rm -f $saveds
        fi
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd=true || : )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

reset_fluentd_daemonset() {
  muxcerts=$( oc get daemonset logging-fluentd -o yaml | egrep muxcerts ) || :

  if [ "$muxcerts" = "" ]; then
      os::log::debug "$( oc set volumes daemonset/logging-fluentd --add --overwrite \
               --name=muxcerts --default-mode=0400 -t secret -m /etc/fluent/muxkeys --secret-name logging-mux 2>&1 )"
  fi
}

fpod=$( get_running_pod fluentd )
muxpod=$( get_running_pod mux )

os::log::info configure fluentd to use MUX_CLIENT_MODE=minimal - verify logs get through
os::log::debug "$( oc label node --all logging-infra-fluentd- )"
os::cmd::try_until_failure "oc get pod $fpod" $FLUENTD_WAIT_TIME
os::log::debug "$( oc set env daemonset/logging-fluentd MUX_CLIENT_MODE=minimal )"
reset_fluentd_daemonset
os::log::debug "$( oc label node --all logging-infra-fluentd=true )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
wait_for_fluentd_ready
wait_for_fluentd_to_catch_up

# configure fluentd to use MUX_CLIENT_MODE=maximal - verify logs get through
os::log::info configure fluentd to use MUX_CLIENT_MODE=maximal - verify logs get through
os::log::debug "$( oc label node --all logging-infra-fluentd- )"
os::cmd::try_until_failure "oc get pod $fpod" $FLUENTD_WAIT_TIME
os::log::debug "$( oc set env daemonset/logging-fluentd MUX_CLIENT_MODE=maximal )"
reset_fluentd_daemonset
os::log::debug "$( oc label node --all logging-infra-fluentd=true )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
wait_for_fluentd_ready
wait_for_fluentd_to_catch_up

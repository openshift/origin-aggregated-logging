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
        get_fluentd_pod_log $fpod > $ARTIFACT_DIR/mux-client-mode-fluentd-pod.log
    fi
    if [ -n "${muxpod:-}" ] ; then
        get_mux_pod_log $muxpod > $ARTIFACT_DIR/mux-client-mode-mux-pod.log 2>&1
    fi
    if [ -n "${saveds:-}" ] ; then
        if [ -f "${saveds:-}" ]; then
            stop_fluentd 2>&1 | artifact_out
            oc replace --force -f $saveds 2>&1 | artifact_out
            rm -f $saveds
            start_fluentd true 2>&1 | artifact_out
        fi
    fi
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
stop_fluentd $fpod 2>&1 | artifact_out
oc set env daemonset/logging-fluentd MUX_CLIENT_MODE=minimal 2>&1 | artifact_out
reset_fluentd_daemonset
start_fluentd true 2>&1 | artifact_out
fpod=$( get_running_pod fluentd )
wait_for_fluentd_to_catch_up

# configure fluentd to use MUX_CLIENT_MODE=maximal - verify logs get through
os::log::info configure fluentd to use MUX_CLIENT_MODE=maximal - verify logs get through
stop_fluentd $fpod 2>&1 | artifact_out
oc set env daemonset/logging-fluentd MUX_CLIENT_MODE=maximal 2>&1 | artifact_out
reset_fluentd_daemonset
start_fluentd true 2>&1 | artifact_out
fpod=$( get_running_pod fluentd )
wait_for_fluentd_to_catch_up

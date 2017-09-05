#!/bin/bash

# This is a test suite for the MUX_CLIENT_MODE settings

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/deployer/scripts/util.sh"
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/curator"

if [ -n "${DEBUG:-}" ] ; then
    set -x
    curl_output() {
        python -mjson.tool
    }
else
    curl_output() {
        cat > /dev/null 2>&1
    }
fi

# only works if USE_MUX=true
if [ "${USE_MUX:-false}" = true ] ; then
    :
else
    os::log::info USE_MUX set to [${USE_MUX:-}] instead of true - skipping test
    exit 0
fi

# save daemonset
saveds=$( mktemp )
oc get daemonset logging-fluentd -o yaml > $saveds

cleanup() {
    local return_code="$?"
    set +e
    if [ $return_code = 0 ] ; then
        mycmd=os::log::info
    else
        mycmd=os::log::error
    fi
    $mycmd mux-client-mode test finished at $( date )
    # dump the pods before we restart them
    if [ -n "${fpod:-}" ] ; then
        oc logs $fpod > $ARTIFACT_DIR/$fpod.log 2>&1
    fi
    if [ -n "${muxpod:-}" ] ; then
        oc logs $muxpod > $ARTIFACT_DIR/$muxpod.log 2>&1
    fi
    if [ -n "${saveds:-}" ] ; then
        if [ -f "${saveds:-}" ]; then
            os::log::debug "$( oc replace -f $saveds )"
            rm -f $saveds
        fi
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd=true || : )"
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

reset_fluentd_daemonset() {
  muxcerts=`oc get daemonset logging-fluentd -o yaml | egrep muxcerts` || :

  if [ "$muxcerts" = "" ]; then
    oc get daemonset logging-fluentd -o yaml | sed '/volumes:/ a\
      - name: muxcerts\
        secret:\
          defaultMode: 420\
          secretName: logging-mux\
' | oc replace -f -

    oc get daemonset logging-fluentd -o yaml | sed '/volumeMounts:/ a\
        - mountPath: /etc/fluent/muxkeys\
          name: muxcerts\
          readOnly: true\
' | oc replace -f -
  fi
}

os::log::info Starting mux-client-mode test at $( date )

fpod=`get_running_pod fluentd`
muxpod=`get_running_pod mux`

os::log::info configure fluentd to use MUX_CLIENT_MODE=minimal - verify logs get through
os::log::debug "$( oc label node --all logging-infra-fluentd- )"
os::cmd::try_until_failure "oc get pod $fpod"
os::log::debug "$( oc set env daemonset/logging-fluentd MUX_CLIENT_MODE=minimal )"
reset_fluentd_daemonset
os::log::debug "$( oc label node --all logging-infra-fluentd=true )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=`get_running_pod fluentd`
wait_for_fluentd_ready
wait_for_fluentd_to_catch_up

# configure fluentd to use MUX_CLIENT_MODE=maximal - verify logs get through
os::log::info configure fluentd to use MUX_CLIENT_MODE=maximal - verify logs get through
os::log::debug "$( oc label node --all logging-infra-fluentd- )"
os::cmd::try_until_failure "oc get pod $fpod"
os::log::debug "$( oc set env daemonset/logging-fluentd MUX_CLIENT_MODE=maximal )"
reset_fluentd_daemonset
os::log::debug "$( oc label node --all logging-infra-fluentd=true )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=`get_running_pod fluentd`
wait_for_fluentd_ready
wait_for_fluentd_to_catch_up

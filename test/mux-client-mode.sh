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

# save setting
use_mux_client=${USE_MUX_CLIENT:-}
mux_client_mode=${MUX_CLIENT_MODE:-}

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
    envvars=""
    if [ -n "${use_mux_client:-}" ] ; then
        envvars="$envvars USE_MUX_CLIENT=$use_mux_client"
    fi
    if [ -n "${mux_client_mode:-}" ] ; then
        envvars="$envvars MUX_CLIENT_MODE=$mux_client_mode"
    fi
    if [ -n "$envvars" ] ; then
        # these will restart fluentd - but don't wait for restart
        os::log::debug "$( oc set env daemonset/logging-fluentd $envvars )"
    else
        # just remove it
        os::log::debug "$( oc set env daemonset/logging-fluentd MUX_CLIENT_MODE- )"
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd=true || : )"
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

os::log::info Starting mux-client-mode test at $( date )

fpod=`get_running_pod fluentd`
muxpod=`get_running_pod mux`

os::log::info configure fluentd to use MUX_CLIENT_MODE=minimal - verify logs get through
os::log::debug "$( oc label node --all logging-infra-fluentd- )"
os::cmd::try_until_failure "oc get pod $fpod"
os::log::debug "$( oc set env daemonset/logging-fluentd MUX_CLIENT_MODE=minimal )"
os::log::debug "$( oc label node --all logging-infra-fluentd=true )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=`get_running_pod fluentd`
wait_for_fluentd_ready
wait_for_fluentd_to_catch_up

# configure fluentd to use MUX_CLIENT_MODE=full_no_k8s_meta - verify logs get through
os::log::info configure fluentd to use MUX_CLIENT_MODE=full_no_k8s_meta - verify logs get through
os::log::debug "$( oc label node --all logging-infra-fluentd- )"
os::cmd::try_until_failure "oc get pod $fpod"
os::log::debug "$( oc set env daemonset/logging-fluentd MUX_CLIENT_MODE=full_no_k8s_meta )"
os::log::debug "$( oc label node --all logging-infra-fluentd=true )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=`get_running_pod fluentd`
wait_for_fluentd_ready
wait_for_fluentd_to_catch_up


#!/bin/bash

# This is a test suite for the ES_COPY settings

# doesn't currently work with mux
if [ -n "${MUX_CLIENT_MODE:-}" ] ; then
    echo $0 does not currently work with MUX_CLIENT_MODE - skipping
    exit 0
fi

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/deployer/scripts/util.sh"
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/es-copy"

if [ -n "${DEBUG:-}" ] ; then
    set -x
fi

# save current fluentd daemonset
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
    $mycmd es-copy test finished at $( date )
    # dump the pod before we restart it
    if [ -n "${fpod:-}" ] ; then
        oc logs $fpod > $ARTIFACT_DIR/$fpod.log 2>&1
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd- 2>&1 || : )"
    os::cmd::try_until_failure "oc get pod $fpod"
    if [ -n "${saveds:-}" -a -f "${saveds:-}" ] ; then
        os::log::debug "$( oc replace --force -f $saveds )"
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd=true || : )"
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

os::log::info Starting es-copy test at $( date )

# first, make sure copy is off
os::log::debug "$( oc set env daemonset/logging-fluentd ES_COPY=false )"
# if it was true, changing the value will trigger a restart
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
wait_for_fluentd_ready
os::cmd::expect_success wait_for_fluentd_to_catch_up

envvars=""
turnoffcopysettings=""
# for every ES_ or OPS_ setting, create a copy called ES_COPY_ or OPS_COPY_
for k_eq_val in $( oc set env daemonset/logging-fluentd --list | grep -v \^# ) ; do
    case "$k_eq_val" in
        ES_COPY_*) continue ;;
        OPS_COPY_*) continue ;;
        ES_*) new=$( echo $k_eq_val | sed s/ES_/ES_COPY_/ ); envvars="$envvars $new" ;;
        OPS_*) new=$( echo $k_eq_val | sed s/OPS_/OPS_COPY_/ ); envvars="$envvars $new" ;;
        *) continue ;;
    esac
    val=$( echo $new | sed 's/=.*$//' )
    turnoffcopysettings="$turnoffcopysettings ${val}-"
done

envvars="$envvars ES_COPY=true ES_COPY_SCHEME=https OPS_COPY_SCHEME=https"
turnoffcopysettings="$turnoffcopysettings ES_COPY- ES_COPY_SCHEME- OPS_COPY_SCHEME-"
if [ -n "${DEBUG:-}" ] ; then
    envvars="$envvars VERBOSE=true"
    turnoffcopysettings="$turnoffcopysettings VERBOSE-"
fi
# turn on all of the COPY settings
os::log::debug "$( oc set env daemonset/logging-fluentd $envvars )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )

wait_for_fluentd_ready
os::cmd::expect_success "wait_for_fluentd_to_catch_up '' '' 2"

# turn off the COPY settings
os::log::debug "$( oc set env daemonset/logging-fluentd $turnoffcopysettings )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )

wait_for_fluentd_ready
os::cmd::expect_success wait_for_fluentd_to_catch_up

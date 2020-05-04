#!/bin/bash

# This is a test suite for the fluent-plugin-remote-syslog settings.
# These tests verify that the configuration files are properly generated based
# on the values of the environment variables.

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 2 * minute ))}
REMOTE_WAIT_TIME=$(( 10 * minute ))

os::test::junit::declare_suite_start "Remote Syslog Configuration Tests"

# save daemonset
saveds=$( mktemp )
oc get --export $fluentd_ds -o yaml > $saveds

os::log::info Starting fluentd-plugin-remote-syslog tests at $( date )

cleanup() {
    local return_code="$?"
    set +e

    if [ $return_code -ne 0 ]; then
        artifact_log "oc get pods"
        oc get pods 2>&1 | artifact_out
        fpod=$( oc get pods --selector component=fluentd -o name | awk -F'/' '{print $2}' )
        get_fluentd_pod_log $fpod > $ARTIFACT_DIR/remote-syslog-${fpod}.log
        oc get events > $ARTIFACT_DIR/remote-syslog-events.txt 2>&1
    fi
    oc logs remote-syslog-listener > $ARTIFACT_DIR/remote-syslog-listener.log 2>&1
    oc delete pod remote-syslog-listener 2>&1 | artifact_out

    stop_fluentd "${fpod:-}" $FLUENTD_WAIT_TIME 2>&1 | artifact_out
    if [ -n "${saveds:-}" -a -f "${saveds:-}" ] ; then
        oc replace --force -f $saveds 2>&1 | artifact_out
    fi
    start_fluentd true 2>&1 | artifact_out

    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

my_remote_syslog_host=$( oc set env $fluentd_ds --list | awk -F'=' '/^REMOTE_SYSLOG_HOST=/ {print $2}' || : )

if [ -n "$my_remote_syslog_host" ]; then
    title="Test 0, checking user configured REMOTE_SYSLOG_HOST is respected"
    os::log::info $title

    stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out
    oc set env $fluentd_ds USE_REMOTE_SYSLOG=true 2>&1 | artifact_out
    start_fluentd true 2>&1 | artifact_out
    mypod=$( get_running_pod fluentd )
    os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf"
    os::cmd::expect_success_and_text "oc exec $mypod grep 'remote_syslog' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" "remote_syslog ${my_remote_syslog_host}"
    artifact_log $title $mypod
fi

title="Test 1, expecting generate_syslog_config.rb to have created configuration file"
os::log::info $title

# make sure fluentd is running after previous test
os::cmd::try_until_text "get_running_pod fluentd" "fluentd"
stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out

# choosing an unrealistic REMOTE_SYSLOG_HOST
oc set env $fluentd_ds USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=111.222.111.222 2>&1 | artifact_out
start_fluentd true 2>&1 | artifact_out

mypod=$( get_running_pod fluentd )
os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $REMOTE_WAIT_TIME
artifact_log $title $mypod

title="Test 2, expecting generate_syslog_config.rb to not create a configuration file"
os::log::info $title

stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out

oc set env $fluentd_ds USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST- 2>&1 | artifact_out
start_fluentd true 2>&1 | artifact_out

mypod=$( get_running_pod fluentd )
os::cmd::try_until_failure "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $REMOTE_WAIT_TIME
artifact_log $title $mypod

title="Test 3, expecting generate_syslog_config.rb to generate multiple stores"
os::log::info $title

stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out

oc set env $fluentd_ds USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_HOST2=127.0.0.1 2>&1 | artifact_out
start_fluentd true 2>&1 | artifact_out

mypod=$( get_running_pod fluentd )
os::cmd::try_until_text "oc exec $mypod grep '<store>' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf | wc -l" '^2$' $REMOTE_WAIT_TIME
artifact_log $title $mypod

title="Test 4, making sure tag_key=message does not cause remote-syslog plugin crash"
os::log::info $title

stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out

oc set env $fluentd_ds USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_TAG_KEY=message REMOTE_SYSLOG_HOST2- 2>&1 | artifact_out
start_fluentd true 2>&1 | artifact_out

mypod=$( get_running_pod fluentd )
mycmd=get_fluentd_pod_log
os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $REMOTE_WAIT_TIME
os::cmd::expect_success "oc exec $mypod grep 'tag_key message' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf"
os::cmd::expect_success_and_not_text "$mycmd $mypod" "nil:NilClass"

artifact_log $title $mypod

title="Test 5, making sure tag_key=bogus does not cause remote-syslog plugin crash"
os::log::info $title

stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out

oc set env $fluentd_ds USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_TAG_KEY=bogus 2>&1 | artifact_out
start_fluentd true 2>&1 | artifact_out

mypod=$( get_running_pod fluentd )
mycmd=get_fluentd_pod_log
os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $REMOTE_WAIT_TIME
os::cmd::expect_success "oc exec $mypod grep 'tag_key bogus' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf"
os::cmd::expect_success_and_not_text "$mycmd $mypod" "nil:NilClass"
artifact_log $title $mypod

title="Test 6-1, start a syslog listener - test TCP syslog from fluentd"
os::log::info $title

# get fluentd image
fimage=$( oc get pods -l component=fluentd -o jsonpath='{.items[0].spec.containers[0].image}' )
# create pod remote-syslog-listener
oc process -p NAMESPACE=$LOGGING_NS -p IMAGE="$fimage" \
    -f $OS_O_A_L_DIR/hack/testing/templates/remote-syslog-listener-template.yaml | \
    oc create -f - 2>&1 | artifact_out
os::cmd::try_until_text "oc get pod remote-syslog-listener --template='{{.status.podIP}}'" "[0-9]" $REMOTE_WAIT_TIME
myhost=$( oc get pod remote-syslog-listener --template='{{.status.podIP}}' )
UDPPORT=24285
TCPPORT=24286

# make sure fluentd is running after previous test
os::cmd::try_until_text "get_running_pod fluentd" "fluentd"
stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out
oc set env $fluentd_ds USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=$myhost REMOTE_SYSLOG_PORT=$TCPPORT \
    REMOTE_SYSLOG_USE_RECORD=true REMOTE_SYSLOG_SEVERITY=info \
    REMOTE_SYSLOG_TAG_KEY='ident,systemd.u.SYSLOG_IDENTIFIER,local1.err' 2>&1 | artifact_out
start_fluentd true 2>&1 | artifact_out

mypod=$( get_running_pod fluentd )
mycmd=get_fluentd_pod_log
fpod=$mypod
os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $REMOTE_WAIT_TIME
$mycmd $mypod > $ARTIFACT_DIR/remote-syslog-$mypod.log 2>&1
oc exec $mypod -- head -n 60 /etc/fluent/fluent.conf /etc/fluent/configs.d/openshift/output-operations.conf \
    /etc/fluent/configs.d/openshift/output-applications.conf /etc/fluent/configs.d/dynamic/output-remote-syslog.conf | artifact_out || :
oc exec $fpod -- find /etc/fluent/configs.d -name \*.conf -ls | artifact_out || :
oc exec $fpod -- cat /etc/fluent/configs.d/openshift/output-operations.conf | artifact_out || :
oc exec $fpod -- find /etc/fluent/configs.d -name \*.conf -exec grep -C 10 retry_es_ops {} /dev/null \; | artifact_out || :

# wait for the precise formatted logs are found in pod remote-syslog-listener logs

getappsmsg() {
    appsmessage=$1
    # file containing search output is $2
}

getopsmsg() {
    opsmessage=$1
    # file containing search output is $2
}

rc=0
if ! wait_for_fluentd_to_catch_up getappsmsg getopsmsg ; then
    rc=1
fi
if ! os::cmd::try_until_text "oc logs remote-syslog-listener" "$opsmessage" $REMOTE_WAIT_TIME ; then
    rc=1
fi
if ! os::cmd::try_until_text "oc logs remote-syslog-listener" "$appsmessage" $REMOTE_WAIT_TIME ; then
    rc=1
fi
if [ $rc -eq 1 ] ; then
    exit 1
fi

title="Test 6-2, UDP syslog from fluentd"
os::log::info $title

# make sure fluentd is running after previous test
os::cmd::try_until_text "get_running_pod fluentd" "fluentd"
stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out
oc set env $fluentd_ds USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=$myhost REMOTE_SYSLOG_PORT=$UDPPORT \
    REMOTE_SYSLOG_USE_RECORD=true REMOTE_SYSLOG_SEVERITY=info \
    REMOTE_SYSLOG_TAG_KEY='ident,systemd.u.SYSLOG_IDENTIFIER,local1.err' \
    REMOTE_SYSLOG_TYPE=syslog 2>&1 | artifact_out
start_fluentd true 2>&1 | artifact_out

mypod=$( get_running_pod fluentd )
mycmd=get_fluentd_pod_log
os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $REMOTE_WAIT_TIME
$mycmd $mypod > $ARTIFACT_DIR/remote-syslog-$mypod.log 2>&1
oc exec $mypod -- head -n 60 /etc/fluent/fluent.conf /etc/fluent/configs.d/openshift/output-operations.conf \
    /etc/fluent/configs.d/openshift/output-applications.conf /etc/fluent/configs.d/dynamic/output-remote-syslog.conf | artifact_out || :

rc=0
if ! wait_for_fluentd_to_catch_up getappsmsg getopsmsg ; then
    rc=1
fi
if ! os::cmd::try_until_text "oc logs remote-syslog-listener" "$opsmessage" $REMOTE_WAIT_TIME ; then
    rc=1
fi
if ! os::cmd::try_until_text "oc logs remote-syslog-listener" "$appsmessage" $REMOTE_WAIT_TIME ; then
    rc=1
fi
if [ $rc -eq 1 ] ; then
    exit 1
fi

title="Test 7, no tag_key"
os::log::info $title

# make sure fluentd is running after previous test
os::cmd::try_until_text "get_running_pod fluentd" "fluentd"
stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out
oc set env $fluentd_ds USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=$myhost REMOTE_SYSLOG_PORT=$TCPPORT \
    REMOTE_SYSLOG_USE_RECORD=true REMOTE_SYSLOG_SEVERITY=info REMOTE_SYSLOG_TYPE- REMOTE_SYSLOG_TAG_KEY- 2>&1 | artifact_out
start_fluentd true 2>&1 | artifact_out

mypod=$( get_running_pod fluentd )
mycmd=get_fluentd_pod_log
os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $REMOTE_WAIT_TIME

artifact_log $title $mypod

rc=0
if ! wait_for_fluentd_to_catch_up getappsmsg getopsmsg ; then
    rc=1
fi
if ! os::cmd::try_until_text "oc logs remote-syslog-listener" "$opsmessage" $REMOTE_WAIT_TIME ; then
    rc=1
fi
if ! os::cmd::try_until_text "oc logs remote-syslog-listener" "$appsmessage" $REMOTE_WAIT_TIME ; then
    rc=1
fi
if [ $rc -eq 1 ] ; then
    exit 1
fi

hasNoMethodError()
{
    no_tag_key_log=$( mktemp )
    $mycmd $mypod > $ARTIFACT_DIR/hasNoMethodError.$mypod.log
    $mycmd $mypod > $no_tag_key_log
    found=$( grep NoMethodError $no_tag_key_log || : )
    rm -f $no_tag_key_log
    if [ -z "$found" ]; then
        artifact_log "good - no NoMethodError in the no tag_key case"
        return 0
    else
        artifact_log "failed - NoMethodError found in the no tag_key case"
        return 1
    fi
}
hasNoMethodError

#!/bin/bash

# This is a test suite for the fluent-plugin-remote-syslog settings.
# These tests verify that the configuration files are properly generated based
# on the values of the environment variables.

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 2 * minute ))}

os::test::junit::declare_suite_start "Remote Syslog Configuration Tests"

# save daemonset
saveds=$( mktemp )
oc export ds/logging-fluentd -o yaml > $saveds

# restore configs back to how it was before we ran our tests
function reset_fluentd_daemonset() {
  os::log::info Restoring original fluentd daemonset environment variable
  os::log::debug "$( oc replace -f $saveds )"
}

# bz1515715 -- check if mux is enabled.
savemuxdc=""
if oc get dc/logging-mux > /dev/null 2>&1 ; then
  savemuxdc=$( mktemp )
  oc export dc/logging-mux -o yaml > $savemuxdc
fi

function reset_mux_deployconfig() {
  if [ "$savemuxdc" != "" ]; then
    os::log::info Restoring original mux deployconfig environment variable
    os::log::debug "$( oc replace -f $savemuxdc )"
  fi
}

os::log::info Starting fluentd-plugin-remote-syslog tests at $( date )

my_remote_syslog_host=$( oc set env ds/logging-fluentd --list | grep REMOTE_SYSLOG_HOST | awk -F'=' '{print $2}' || : )
if [ -n "${my_remote_syslog_host:-}" ] ; then
  os::log::info Test 0, checking user configured REMOTE_SYSLOG_HOST is respected.
  os::log::debug "$( oc label node --all logging-infra-fluentd- )"
  os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
  os::log::debug "$( oc set env ds/logging-fluentd USE_REMOTE_SYSLOG=true )"
  os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
  os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
  fpod=$( get_running_pod fluentd )
  os::cmd::try_until_success "oc exec $fpod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf"
  os::cmd::expect_success_and_text "oc exec $fpod grep 'remote_syslog' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" "remote_syslog ${my_remote_syslog_host}"
fi

os::log::info Test 1, expecting generate_syslog_config.rb to have created configuration file

# make sure fluentd is running after previous test
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
os::log::debug "$( oc label node --all logging-infra-fluentd- )"
os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

os::log::debug "$( oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 )"
os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

fpod=$( get_running_pod fluentd )
os::cmd::try_until_success "oc exec $fpod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf"


os::log::info Test 2, expecting generate_syslog_config.rb to not create a configuration file

os::log::debug "$( oc label node --all logging-infra-fluentd- )"
os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

os::log::debug "$( oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST- )"
os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "


fpod=$( get_running_pod fluentd )
os::cmd::try_until_failure "oc exec $fpod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf"


os::log::info Test 3, expecting generate_syslog_config.rb to generate multiple stores

os::log::debug "$( oc label node --all logging-infra-fluentd- )"
os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

os::log::debug "$( oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_HOST2=127.0.0.1 )"
os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

fpod=$( get_running_pod fluentd )
os::cmd::try_until_text "oc exec $fpod grep '<store>' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf | wc -l" '^2$'


reset_fluentd_daemonset

if [ "$savemuxdc" != "" ]; then

  os::log::info Test 6, verify openshift_logging_mux_remote_syslog_host is respected in the mux pod

  if [ -n "${DEBUG:-}" ] ; then
    echo Test 6, verify openshift_logging_mux_remote_syslog_host is respected in the mux pod >> $extra_rsyslog_artifacts
  fi

  # make sure mux is running.
  os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "

  os::log::debug "$( oc scale --replicas=0 dc logging-mux )"
  os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" "0" $FLUENTD_WAIT_TIME

  # bz1515715 -- is openshift_logging_mux_remote_syslog_host set?
  my_remote_syslog_host=$( oc set env dc/logging-mux --list | grep REMOTE_SYSLOG_HOST | awk -F'=' '{print $2}' || : )
  if [ -n "${my_remote_syslog_host:-}" ] ; then
    os::log::debug "$( oc set env dc/logging-mux USE_REMOTE_SYSLOG=true )"
    os::log::debug "$( oc scale --replicas=1 dc logging-mux )"
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running "
    mpod=$( get_running_pod mux )
    if [ -n "${DEBUG:-}" ] ; then
      oc logs $mpod >> $extra_rsyslog_artifacts 2>&1
      echo "output-remote-syslog.conf: " >> $extra_rsyslog_artifacts
      oc exec $mpod -- cat /etc/fluent/configs.d/dynamic/output-remote-syslog.conf >> $extra_rsyslog_artifacts
    fi
    os::cmd::try_until_success "oc exec $mpod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf"
    os::cmd::expect_success_and_text "oc exec $mpod grep 'remote_syslog' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" "remote_syslog ${my_remote_syslog_host}"
    os::log::debug "$( oc scale --replicas=0 dc logging-mux )"
    os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" "0" $FLUENTD_WAIT_TIME
  fi

  os::log::debug "$( oc set env dc/logging-mux USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 )"
  os::log::debug "$( oc scale --replicas=1 dc logging-mux )"
  os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running "

  mpod=$( get_running_pod mux )
  os::cmd::try_until_success "oc exec $mpod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf"
  os::cmd::expect_success_and_text "oc exec $mpod grep 'remote_syslog' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" "remote_syslog 127.0.0.1"
  if [ -n "${DEBUG:-}" ] ; then
    oc logs $mpod >> $extra_rsyslog_artifacts 2>&1
    echo "output-remote-syslog.conf: " >> $extra_rsyslog_artifacts
    oc exec $mpod -- cat /etc/fluent/configs.d/dynamic/output-remote-syslog.conf >> $extra_rsyslog_artifacts
  fi

  reset_mux_deployconfig
fi

os::test::junit::reconcile_output

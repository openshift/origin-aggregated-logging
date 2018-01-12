#!/bin/bash

# This is a test suite for the fluent-plugin-remote-syslog settings.
# These tests verify that the configuration files are properly generated based
# on the values of the environment variables.

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 2 * minute ))}
MUX_WAIT_TIME=$(( 10 * minute ))
ALTPORT=601

os::test::junit::declare_suite_start "Remote Syslog Configuration Tests"

# save daemonset
saveds=$( mktemp )
oc export ds/logging-fluentd -o yaml > $saveds

# switch pods type depending on the mux configuration
fluentdtype="fluentd"
mpod=$( get_running_pod mux )
if [ -n "${mpod:-}" ]; then
    # mux is configured; make sure mux client fluentd runs as maximal mode.
    os::log::debug "$( oc label node --all logging-infra-fluentd- )"
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
    os::log::debug "$( oc set env ds/logging-fluentd MUX_CLIENT_MODE=maximal )"
    os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    fluentdtype="mux"
fi

# restore configs back to how it was before we ran our tests
function reset_fluentd_daemonset() {
  os::log::info Restoring original fluentd daemonset / mux deploymentconfig environment variable
  os::log::debug "$( oc replace -f $saveds )"
}

artifact_log Starting fluentd-plugin-remote-syslog tests on $fluentdtype at "$( date )"

os::log::info Starting fluentd-plugin-remote-syslog tests on $fluentdtype at $( date )

cleanup() {
    local return_code="$?"
    set +e

    if [ $return_code -ne 0 ]; then
       artifact_log "oc get pods"
       oc get pods 2>&1 | artifact_out || :
       artifact_log "/var/log/messages files"
       sudo ls -ltZ /var/log/messages* 2>&1 | artifact_out || :
       artifact_log "Sample of /var/log/messages"
       sudo tail -n 30 /var/log/messages 2>&1 | artifact_out || :
       artifact_log "Sample of /var/log/messages DONE"
       if [ "$fluentdtype" = "fluentd" ] ; then
           mypod=$( get_running_pod fluentd )
       else
           mypod=$( get_running_pod fluentd )
           artifact_log log from $mypod
           oc logs $mypod 2>&1 | artifact_out || :
           mypod=$( get_running_pod mux )
       fi
       artifact_log log from $mypod
       oc logs $mypod 2>&1 | artifact_out || :
       artifact_log get events
       oc get events 2>&1 | artifact_out || :
       artifact_log fluentd logs in journalctl output
       sudo journalctl | grep fluentd | tail -n 30 2>&1 | artifact_out || :
       artifact_log rsyslog logs in journalctl output
       sudo journalctl | grep rsyslogd | tail -n 30 2>&1 | artifact_out || :
       artifact_log something in audit.log
       sudo grep rsyslog /var/log/audit/audit.log 2>&1 | artifact_out || :
    fi

    if [ "$fluentdtype" = "fluentd" ] ; then
        reset_fluentd_daemonset
    else
        os::log::debug "$( oc scale --replicas=0 dc logging-mux )"
        os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" "0" $MUX_WAIT_TIME
        os::log::debug "$( oc set env dc/logging-mux USE_REMOTE_SYSLOG=false REMOTE_SYSLOG_HOST- REMOTE_SYSLOG_USE_RECORD- REMOTE_SYSLOG_PORT=514 )"
        os::log::debug "$( oc scale --replicas=1 dc logging-mux )"
        os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running " $MUX_WAIT_TIME

        os::log::debug "$( oc label node --all logging-infra-fluentd- )"
        os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
        os::log::debug "$( oc set env ds/logging-fluentd MUX_CLIENT_MODE- )"
        os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
        os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    fi

    # Resetting rsyslogd
    #   Provides TCP syslog reception
    #   $ModLoad imtcp
    #   $InputTCPServerRun 514
    if [ -f ${rsyslogconfbakup:-""} ]; then
        sudo cp $rsyslogconfbakup /etc/rsyslog.conf
    fi
    if [ -f ${rsyslogconfbakup2:-""} ]; then
        sudo mv $rsyslogconfbakup2 /etc/rsyslog.d
    fi
    os::cmd::expect_success "sudo service rsyslog restart"

    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

if [ "$fluentdtype" = "fluentd" ] ; then
    my_remote_syslog_host=$( oc set env ds/logging-fluentd --list | grep REMOTE_SYSLOG_HOST | awk -F'=' '{print $2}' || : )
else
    my_remote_syslog_host=$( oc set env dc/logging-mux --list | grep REMOTE_SYSLOG_HOST | awk -F'=' '{print $2}' || : )
fi

if [ -n "$my_remote_syslog_host" ]; then
    title="Test 0, checking user configured REMOTE_SYSLOG_HOST is respected"
    os::log::info $title

    if [ "$fluentdtype" = "fluentd" ] ; then
        os::log::debug "$( oc label node --all logging-infra-fluentd- )"
        os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
        os::log::debug "$( oc set env ds/logging-fluentd USE_REMOTE_SYSLOG=true )"
        os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
        os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
        mypod=$( get_running_pod fluentd )
    else
        # make sure mux is running after previous test
        os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
        os::log::debug "$( oc scale --replicas=0 dc logging-mux )"
        os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" "0" $MUX_WAIT_TIME
        os::log::debug "$( oc set env dc/logging-mux USE_REMOTE_SYSLOG=true )"
        os::log::debug "$( oc scale --replicas=1 dc logging-mux )"
        os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running " $MUX_WAIT_TIME
        mypod=$( get_running_pod mux )
    fi
    os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf"
    os::cmd::expect_success_and_text "oc exec $mypod grep 'remote_syslog' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" "remote_syslog ${my_remote_syslog_host}"
    artifact_log $title $mypod
fi


title="Test 1, expecting generate_syslog_config.rb to have created configuration file"
os::log::info $title

if [ "$fluentdtype" = "fluentd" ] ; then
    # make sure fluentd is running after previous test
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    os::log::debug "$( oc label node --all logging-infra-fluentd- )"
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

    # choosing an unrealistic REMOTE_SYSLOG_HOST
    os::log::debug "$( oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=111.222.111.222 )"
    os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    mypod=$( get_running_pod fluentd )
else
    # make sure mux is running after previous test
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
    os::log::debug "$( oc scale --replicas=0 dc logging-mux )"
    os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" "0" $MUX_WAIT_TIME
    # choosing an unrealistic REMOTE_SYSLOG_HOST
    os::log::debug "$( oc set env dc/logging-mux USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=111.222.111.222 )"
    os::log::debug "$( oc scale --replicas=1 dc logging-mux )"
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running " $MUX_WAIT_TIME

    mypod=$( get_running_pod mux )
fi
os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $MUX_WAIT_TIME
artifact_log $title $mypod


title="Test 2, expecting generate_syslog_config.rb to not create a configuration file"
os::log::info $title

if [ "$fluentdtype" = "fluentd" ] ; then
    os::log::debug "$( oc label node --all logging-infra-fluentd- )"
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

    os::log::debug "$( oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST- )"
    os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    mypod=$( get_running_pod fluentd )
else
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
    os::log::debug "$( oc scale --replicas=0 dc logging-mux )"
    os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" "0" $MUX_WAIT_TIME
    os::log::debug "$( oc set env dc/logging-mux USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST- )"
    os::log::debug "$( oc scale --replicas=1 dc logging-mux )"
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running " $MUX_WAIT_TIME

    mypod=$( get_running_pod mux )
fi
os::cmd::try_until_failure "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $MUX_WAIT_TIME
artifact_log $title $mypod


title="Test 3, expecting generate_syslog_config.rb to generate multiple stores"
os::log::info $title

if [ "$fluentdtype" = "fluentd" ] ; then
    os::log::debug "$( oc label node --all logging-infra-fluentd- )"
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

    os::log::debug "$( oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_HOST2=127.0.0.1 )"
    os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    mypod=$( get_running_pod fluentd )
else
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
    os::log::debug "$( oc scale --replicas=0 dc logging-mux )"
    os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" "0" $MUX_WAIT_TIME
    os::log::debug "$( oc set env dc/logging-mux USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_HOST2=127.0.0.1 )"
    os::log::debug "$( oc scale --replicas=1 dc logging-mux )"
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running " $MUX_WAIT_TIME

    mypod=$( get_running_pod mux )
fi
os::cmd::try_until_text "oc exec $mypod grep '<store>' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf | wc -l" '^2$' $MUX_WAIT_TIME
artifact_log $title $mypod


title="Test 4, making sure tag_key=message does not cause remote-syslog plugin crash"
os::log::info $title

if [ "$fluentdtype" = "fluentd" ] ; then
    os::log::debug "$( oc label node --all logging-infra-fluentd- )"
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

    os::log::debug "$( oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_TAG_KEY=message REMOTE_SYSLOG_HOST2-)"
    os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    mypod=$( get_running_pod fluentd )
else
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
    os::log::debug "$( oc scale --replicas=0 dc logging-mux )"
    os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" "0" $MUX_WAIT_TIME
    os::log::debug "$( oc set env dc/logging-mux USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_TAG_KEY=message REMOTE_SYSLOG_HOST2-)"
    os::log::debug "$( oc scale --replicas=1 dc logging-mux )"
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running " $MUX_WAIT_TIME

    mypod=$( get_running_pod mux )
fi
os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $MUX_WAIT_TIME
os::cmd::expect_success "oc exec $mypod grep 'tag_key message' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf"
os::cmd::expect_success_and_not_text "oc logs $mypod" "nil:NilClass"

artifact_log $title $mypod


title="Test 5, making sure tag_key=bogus does not cause remote-syslog plugin crash"
os::log::info $title

if [ "$fluentdtype" = "fluentd" ] ; then
    os::log::debug "$( oc label node --all logging-infra-fluentd- )"
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

    os::log::debug "$( oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_TAG_KEY=bogus)"
    os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    mypod=$( get_running_pod fluentd )
else
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
    os::log::debug "$( oc scale --replicas=0 dc logging-mux )"
    os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" "0" $MUX_WAIT_TIME
    os::log::debug "$( oc set env dc/logging-mux USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_TAG_KEY=bogus)"
    os::log::debug "$( oc scale --replicas=1 dc logging-mux )"
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running " $MUX_WAIT_TIME

    mypod=$( get_running_pod mux )
fi
os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $MUX_WAIT_TIME
os::cmd::expect_success "oc exec $mypod grep 'tag_key bogus' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf"
os::cmd::expect_success_and_not_text "oc logs $mypod" "nil:NilClass"
artifact_log $title $mypod


title="Test 6, use rsyslogd on the node"
os::log::info $title

artifact_log iptables ACCEPT ${ALTPORT}
sudo iptables -A INPUT -m tcp -p tcp --dport ${ALTPORT} -j ACCEPT 2>&1 | artifact_out || :
sudo iptables -L 2>&1 | artifact_out || :

# Make sure rsyslogd is listening on port 514 up and running
#   Provides TCP syslog reception
#   $ModLoad imtcp
#   $InputTCPServerRun 514 -> 601
rsyslogconfbakup=$( mktemp )
artifact_log ORIGINAL /etc/rsyslog.conf
cat /etc/rsyslog.conf 2>&1 | artifact_out
artifact_log ORIGINAL /etc/rsyslog.conf END
cp /etc/rsyslog.conf $rsyslogconfbakup
sudo sed -i -e 's/^#*\(\$ModLoad imtcp\)/\1/' -e "s/^#*\(\$InputTCPServerRun\) 514/\1 ${ALTPORT}/" \
         -e 's/\(\$ModLoad imuxsock\)/#\1/' -e 's/\(\$ModLoad imjournal\)/#\1/' -e 's/\(\$OmitLocalLogging\)/#\1/' \
         -e 's/\(\$IMJournalStateFile imjournal.state\)/#\1/' -e 's/\(\$ActionFileEnableSync\)/#\1/' \
         -e 's/\(#### RULES .*\)/\1\n\$template precise,"%syslogpriority%,%syslogfacility%,%timegenerated%,%HOSTNAME%,%syslogtag%,%msg%\\n"/' \
         -e 's/^*.info;mail.none;authpriv.none;cron.none *\(\/var\/log\/messages\)/*.* \1;precise/' \
         /etc/rsyslog.conf
sudo ls -l /etc/rsyslog.d | artifact_out || :
rsyslogconfbakup2=/tmp/listen.conf
if [ -f /etc/rsyslog.d/listen.conf ]; then
    sudo mv /etc/rsyslog.d/listen.conf $rsyslogconfbakup2
fi
artifact_log MODIFIED /etc/rsyslog.conf
cat /etc/rsyslog.conf 2>&1 | artifact_out
artifact_log MODIFIED /etc/rsyslog.conf END

artifact_log Before restarting rsyslog
sudo service rsyslog status 2>&1 | artifact_out || :
os::cmd::expect_success "sudo service rsyslog stop"
sudo mv /var/log/messages /var/log/messages."$( date +%Y%m%d-%H%M%S )" || :
sudo touch /var/log/messages || :
sudo chmod 600 /var/log/messages || :
sudo semanage fcontext -a -t var_log_t -s system_u /var/log/messages || :
sudo restorecon -vF /var/log/messages || :
os::cmd::expect_success "sudo service rsyslog start"
artifact_log After restarted rsyslog
sudo service rsyslog status 2>&1 | artifact_out || :
artifact_log journald.conf
sudo cat /etc/systemd/journald.conf 2>&1 | artifact_out || :

myhost=$( hostname )

if [ "$fluentdtype" = "fluentd" ] ; then
    # make sure fluentd is running after previous test
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    os::log::debug "$( oc label node --all logging-infra-fluentd- )"
    os::cmd::try_until_text "oc get daemonset/logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

    os::log::debug "$( oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=$myhost REMOTE_SYSLOG_PORT=${ALTPORT} REMOTE_SYSLOG_USE_RECORD=true REMOTE_SYSLOG_SEVERITY=info REMOTE_SYSLOG_TAG_KEY='ident,systemd.u.SYSLOG_IDENTIFIER' )"
    os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    mypod=$( get_running_pod fluentd )
else
    # make sure fluentd is running after previous test
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    os::log::debug "$( oc label node --all logging-infra-fluentd- )"
    os::cmd::try_until_text "oc get daemonset/logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

    os::log::debug "$( oc set env daemonset/logging-fluentd FORWARD_INPUT_LOG_LEVEL=info )"
    os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    # make sure mux is running after previous test
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
    os::log::debug "$( oc scale --replicas=0 dc logging-mux )"
    os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" "0" $MUX_WAIT_TIME
    os::log::debug "$( oc set env dc/logging-mux FORWARD_INPUT_LOG_LEVEL=info USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=$myhost REMOTE_SYSLOG_PORT=${ALTPORT} REMOTE_SYSLOG_USE_RECORD=true REMOTE_SYSLOG_SEVERITY=info REMOTE_SYSLOG_TAG_KEY='ident,systemd.u.SYSLOG_IDENTIFIER' )"
    os::log::debug "$( oc scale --replicas=1 dc logging-mux )"
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running " $MUX_WAIT_TIME

    mypod=$( get_running_pod mux )
fi
os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $MUX_WAIT_TIME
artifact_log $title $mypod
oc logs $mypod 2>&1 | artifact_out || :
oc exec $mypod -- head -n 60 /etc/fluent/fluent.conf /etc/fluent/configs.d/openshift/output-operations.conf /etc/fluent/configs.d/openshift/output-applications.conf /etc/fluent/configs.d/dynamic/output-remote-syslog.conf | artifact_out || :
artifact_log ping $myhost from $mypod
oc exec $mypod -- ping $myhost -c 3 | artifact_out || :

# wait for the precise formatted logs are found in /var/log/messages
# os::cmd::try_until_text "sudo egrep \"^[0-6],[0-9]*,\" /var/log/messages" "[0-6],[0-9]*,.*" $MUX_WAIT_TIME
# sudo egrep \"^[0-6],[0-9]*,\" /var/log/messages | tail -n 5 | artifact_out || :

artifact_log docker info
docker info | artifact_out || :

mymessage="rsyslogTestMessage-"$( date +%Y%m%d-%H%M%S )
logger -i -p local1.err -t rsyslogTestTag $mymessage
es_pod=$( get_es_pod es )
es_ops_pod=$( get_es_pod es-ops )
es_ops_pod=${es_ops_pod:-$es_pod}
qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"rsyslogTestTag"}}}'
if os::cmd::try_until_text "curl_es ${es_ops_pod} /.operations.*/_count -X POST -d '$qs' | get_count_from_json" 1 $MUX_WAIT_TIME; then
    artifact_log good - found $mymessage
else
    artifact_log failed - not found $mymessage
fi
os::cmd::try_until_text "sudo egrep \"${mymessage}$\" /var/log/messages" ".*${mymessage}.*" $MUX_WAIT_TIME
artifact_log Log test message by logger: $mymessage
sudo egrep "${mymessage}$" /var/log/messages 2>&1 | artifact_out || :

mymessage="testKibanaMessage-"$( date +%Y%m%d-%H%M%S )
add_test_message $mymessage
es_pod=$( get_es_pod es )
qs='{"query":{"match_phrase":{"message":"'"${mymessage}"'"}}}'
if os::cmd::try_until_text "curl_es ${es_pod} /project.logging.*/_count -X POST -d '$qs' | get_count_from_json" 1 $MUX_WAIT_TIME; then
    artifact_log good - found $mymessage
else
    artifact_log failed - not found $mymessage
fi
os::cmd::try_until_text "sudo egrep \"/${mymessage}\" /var/log/messages" ".*${mymessage}.*" $MUX_WAIT_TIME
artifact_log Log test message by kibana: $mymessage
sudo egrep "/${mymessage}" /var/log/messages 2>&1 | artifact_out || :


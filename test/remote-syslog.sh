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
oc get --export ds/logging-fluentd -o yaml > $saveds

# switch pods type depending on the mux configuration
fluentdtype="fluentd"
mpod=$( get_running_pod mux )
if [ -n "${mpod:-}" ]; then
    # mux is configured; make sure mux client fluentd runs as maximal mode.
    os::log::debug "$( oc label node --all logging-infra-fluentd- )"
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" '^0$' $FLUENTD_WAIT_TIME
    oc set env ds/logging-fluentd MUX_CLIENT_MODE=maximal 2>&1 | artifact_out
    oc label node --all logging-infra-fluentd=true --overwrite=true 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    fluentdtype="mux"
    # save mux config
    savemuxdc=$( mktemp )
    oc get --export dc/logging-mux -o yaml > $savemuxdc
fi

os::log::info Starting fluentd-plugin-remote-syslog tests at $( date )

# clear the journal
sudo journalctl --vacuum-size=$( expr 1024 \* 1024 \* 2 ) 2>&1 | artifact_out
sudo systemctl restart systemd-journald 2>&1 | artifact_out

cleanup() {
    local return_code="$?"
    set +e

    if [ $return_code -ne 0 ]; then
        artifact_log "oc get pods"
        oc get pods 2>&1 | artifact_out
        fpod=$( oc get pods --selector component=fluentd -o name | awk -F'/' '{print $2}' )
        oc logs $fpod > $ARTIFACT_DIR/remote-syslog-${fpod}.log 2>&1
        mpod=$( oc get pods --selector component=mux -o name | awk -F'/' '{print $2}' )
        if [ -n "${mpod}" ] ; then
            oc logs $mpod > $ARTIFACT_DIR/remote-syslog-$mpod.log 2>&1
        fi
        oc get events > $ARTIFACT_DIR/remote-syslog-events.txt 2>&1
        sudo journalctl | grep fluentd | tail -n 30 > $ARTIFACT_DIR/remote-syslog-journal-fluentd.log 2>&1
        sudo grep rsyslog /var/log/audit/audit.log > $ARTIFACT_DIR/remote-syslog-audit-rsyslog.log 2>&1
        artifact_log "/var/log/messages files"
        sudo ls -ltZ /var/log/messages* 2>&1 | artifact_out
        sudo tail -n 200 /var/log/messages > $ARTIFACT_DIR/remote-syslog-messages.log 2>&1
        if [ -n "${teststart-:}" ] ; then
            sudo journalctl -S "$teststart" -u rsyslog > $ARTIFACT_DIR/remote-syslog-journal-rsyslog.log 2>&1
            sudo journalctl -S "$teststart" -u systemd-journald > $ARTIFACT_DIR/remote-syslog-journal-journald.log 2>&1
            sudo journalctl -S "$teststart" > $ARTIFACT_DIR/remote-syslog-journal.log 2>&1
        fi
    fi

    oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" '^0$' $FLUENTD_WAIT_TIME
    if [ -n "${saveds:-}" -a -f "${saveds:-}" ] ; then
        oc replace --force -f $saveds 2>&1 | artifact_out
    fi
    oc label node --all logging-infra-fluentd=true --overwrite=true 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    if [ "$fluentdtype" = "mux" ] ; then
        oc scale --replicas=0 dc logging-mux 2>&1 | artifact_out
        os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" '^0$' $MUX_WAIT_TIME
        if [ -n "${savemuxdc:-}" -a -f "${savemuxdc:-}" ] ; then
            oc apply --force -f $savemuxdc 2>&1 | artifact_out
        fi
        oc scale --replicas=1 dc logging-mux 2>&1 | artifact_out
        os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running " $MUX_WAIT_TIME
    fi

    # Resetting rsyslogd
    #   Provides TCP syslog reception
    #   $ModLoad imtcp
    #   $InputTCPServerRun 514
    if [ -n "${rsyslogconfbakup:-}" -a -f "${rsyslogconfbakup:-}" ]; then
        sudo cp $rsyslogconfbakup /etc/rsyslog.conf
    fi
    if [ -n "${rsyslogconfbakup2:-}" -a -f "${rsyslogconfbakup2:-}" ]; then
        sudo mv $rsyslogconfbakup2 /etc/rsyslog.d
    fi
    os::cmd::expect_success "sudo service rsyslog restart"

    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

if [ "$fluentdtype" = "fluentd" ] ; then
    my_remote_syslog_host=$( oc set env ds/logging-fluentd --list | awk -F'=' '/^REMOTE_SYSLOG_HOST=/ {print $2}' || : )
else
    my_remote_syslog_host=$( oc set env dc/logging-mux --list | awk -F'=' '/^REMOTE_SYSLOG_HOST=/ {print $2}' || : )
fi

if [ -n "$my_remote_syslog_host" ]; then
    title="Test 0, checking user configured REMOTE_SYSLOG_HOST is respected"
    os::log::info $title

    if [ "$fluentdtype" = "fluentd" ] ; then
        oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
        os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" '^0$' $FLUENTD_WAIT_TIME
        oc set env ds/logging-fluentd USE_REMOTE_SYSLOG=true 2>&1 | artifact_out
        oc label node --all logging-infra-fluentd=true --overwrite=true 2>&1 | artifact_out
        os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
        mypod=$( get_running_pod fluentd )
    else
        # make sure mux is running after previous test
        os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
        oc scale --replicas=0 dc logging-mux 2>&1 | artifact_out
        os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" '^0$' $MUX_WAIT_TIME
        oc get pods | grep mux 2>&1 | artifact_out || :
        oc get dc 2>&1 | artifact_out
        oc set env dc/logging-mux USE_REMOTE_SYSLOG=true 2>&1 | artifact_out
        oc get pods | grep mux 2>&1 | artifact_out || :
        oc get dc 2>&1 | artifact_out
        oc scale --replicas=1 dc logging-mux 2>&1 | artifact_out
        oc get pods | grep mux 2>&1 | artifact_out || :
        oc get dc 2>&1 | artifact_out
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
    oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" '^0$' $FLUENTD_WAIT_TIME

    # choosing an unrealistic REMOTE_SYSLOG_HOST
    oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=111.222.111.222 2>&1 | artifact_out
    oc label node --all logging-infra-fluentd=true --overwrite=true 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    mypod=$( get_running_pod fluentd )
else
    # make sure mux is running after previous test
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
    oc scale --replicas=0 dc logging-mux 2>&1 | artifact_out
    os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" '^0$' $MUX_WAIT_TIME
    # choosing an unrealistic REMOTE_SYSLOG_HOST
    oc get pods | grep mux 2>&1 | artifact_out || :
    oc get dc 2>&1 | artifact_out
    oc set env dc/logging-mux USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=111.222.111.222 2>&1 | artifact_out
    oc get pods | grep mux 2>&1 | artifact_out || :
    oc get dc 2>&1 | artifact_out
    oc scale --replicas=1 dc logging-mux 2>&1 | artifact_out
    oc get pods | grep mux 2>&1 | artifact_out || :
    oc get dc 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running " $MUX_WAIT_TIME

    mypod=$( get_running_pod mux )
fi
os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $MUX_WAIT_TIME
artifact_log $title $mypod


title="Test 2, expecting generate_syslog_config.rb to not create a configuration file"
os::log::info $title

if [ "$fluentdtype" = "fluentd" ] ; then
    oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" '^0$' $FLUENTD_WAIT_TIME

    oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST- 2>&1 | artifact_out
    oc label node --all logging-infra-fluentd=true --overwrite=true 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    mypod=$( get_running_pod fluentd )
else
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
    oc scale --replicas=0 dc logging-mux 2>&1 | artifact_out
    os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" '^0$' $MUX_WAIT_TIME
    oc set env dc/logging-mux USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST- 2>&1 | artifact_out
    oc scale --replicas=1 dc logging-mux 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running " $MUX_WAIT_TIME

    mypod=$( get_running_pod mux )
fi
os::cmd::try_until_failure "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $MUX_WAIT_TIME
artifact_log $title $mypod


title="Test 3, expecting generate_syslog_config.rb to generate multiple stores"
os::log::info $title

if [ "$fluentdtype" = "fluentd" ] ; then
    oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" '^0$' $FLUENTD_WAIT_TIME

    oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_HOST2=127.0.0.1 2>&1 | artifact_out
    oc label node --all logging-infra-fluentd=true --overwrite=true 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    mypod=$( get_running_pod fluentd )
else
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
    oc scale --replicas=0 dc logging-mux 2>&1 | artifact_out
    os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" '^0$' $MUX_WAIT_TIME
    oc set env dc/logging-mux USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_HOST2=127.0.0.1 2>&1 | artifact_out
    oc scale --replicas=1 dc logging-mux 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running " $MUX_WAIT_TIME

    mypod=$( get_running_pod mux )
fi
os::cmd::try_until_text "oc exec $mypod grep '<store>' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf | wc -l" '^2$' $MUX_WAIT_TIME
artifact_log $title $mypod


title="Test 4, making sure tag_key=message does not cause remote-syslog plugin crash"
os::log::info $title

if [ "$fluentdtype" = "fluentd" ] ; then
    oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" '^0$' $FLUENTD_WAIT_TIME

    oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_TAG_KEY=message REMOTE_SYSLOG_HOST2- 2>&1 | artifact_out
    oc label node --all logging-infra-fluentd=true --overwrite=true 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    mypod=$( get_running_pod fluentd )
else
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
    oc scale --replicas=0 dc logging-mux 2>&1 | artifact_out
    os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" '^0$' $MUX_WAIT_TIME
    oc set env dc/logging-mux USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_TAG_KEY=message REMOTE_SYSLOG_HOST2- 2>&1 | artifact_out
    oc scale --replicas=1 dc logging-mux 2>&1 | artifact_out
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
    oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" '^0$' $FLUENTD_WAIT_TIME

    oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_TAG_KEY=bogus 2>&1 | artifact_out
    oc label node --all logging-infra-fluentd=true --overwrite=true 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    mypod=$( get_running_pod fluentd )
else
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
    oc scale --replicas=0 dc logging-mux 2>&1 | artifact_out
    os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" '^0$' $MUX_WAIT_TIME
    oc set env dc/logging-mux USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_TAG_KEY=bogus 2>&1 | artifact_out
    oc scale --replicas=1 dc logging-mux 2>&1 | artifact_out
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
cat /etc/rsyslog.conf > $ARTIFACT_DIR/remote-syslog-rsyslog.conf.orig
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
cat /etc/rsyslog.conf > $ARTIFACT_DIR/remote-syslog-rsyslog.conf.modified

# date in journalctl -S format
teststart=$( date "+%Y-%m-%d %H:%M:%S" )
artifact_log Before restarting rsyslog
sudo service rsyslog status 2>&1 | artifact_out || :
os::cmd::expect_success "sudo service rsyslog stop"
sudo mv /var/log/messages /var/log/messages."$( date +%Y%m%d-%H%M%S )" || :
sudo touch /var/log/messages || :
sudo chmod 600 /var/log/messages || :
sudo semanage fcontext -a -t var_log_t -s system_u /var/log/messages 2>&1 | artifact_out || :
sudo restorecon -vF /var/log/messages 2>&1 | artifact_out || :
os::cmd::expect_success "sudo service rsyslog start"
artifact_log After restarted rsyslog
sudo service rsyslog status 2>&1 | artifact_out || :
sudo cat /etc/systemd/journald.conf > $ARTIFACT_DIR/remote-syslog-journald.conf

myhost=$( hostname )

if [ "$fluentdtype" = "fluentd" ] ; then
    # make sure fluentd is running after previous test
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
    os::cmd::try_until_text "oc get daemonset/logging-fluentd -o jsonpath='{ .status.numberReady }'" '^0$' $FLUENTD_WAIT_TIME

    oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=$myhost REMOTE_SYSLOG_PORT=${ALTPORT} \
        REMOTE_SYSLOG_USE_RECORD=true REMOTE_SYSLOG_SEVERITY=info \
        REMOTE_SYSLOG_TAG_KEY='ident,systemd.u.SYSLOG_IDENTIFIER,local1.err' 2>&1 | artifact_out
    sudo rm -f /var/log/journal.pos
    sudo rm -rf /var/lib/fluentd/*
    oc label node --all logging-infra-fluentd=true --overwrite=true 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    mypod=$( get_running_pod fluentd )
else
    # make sure mux is running after previous test
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux.* Running "
    oc scale --replicas=0 dc logging-mux 2>&1 | artifact_out
    os::cmd::try_until_text "oc get dc logging-mux -o jsonpath='{ .status.replicas }'" '^0$' $MUX_WAIT_TIME
    oc set env dc/logging-mux FORWARD_INPUT_LOG_LEVEL=info USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=$myhost \
        REMOTE_SYSLOG_PORT=${ALTPORT} REMOTE_SYSLOG_USE_RECORD=true \
        REMOTE_SYSLOG_SEVERITY=info REMOTE_SYSLOG_TAG_KEY='ident,systemd.u.SYSLOG_IDENTIFIER,local1.err' 2>&1 | artifact_out
    oc scale --replicas=1 dc logging-mux 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running " $MUX_WAIT_TIME
    mypod=$( get_running_pod mux )

    # make sure fluentd is running after previous test
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
    os::cmd::try_until_text "oc get daemonset/logging-fluentd -o jsonpath='{ .status.numberReady }'" '^0$' $FLUENTD_WAIT_TIME
    sudo rm -f /var/log/journal.pos
    sudo rm -rf /var/lib/fluentd/*
    oc set env daemonset/logging-fluentd FORWARD_INPUT_LOG_LEVEL=info 2>&1 | artifact_out
    oc label node --all logging-infra-fluentd=true --overwrite=true 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

fi
os::cmd::try_until_success "oc exec $mypod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" $MUX_WAIT_TIME
oc logs $mypod > $ARTIFACT_DIR/remote-syslog-$mypod.log 2>&1
oc exec $mypod -- head -n 60 /etc/fluent/fluent.conf /etc/fluent/configs.d/openshift/output-operations.conf \
    /etc/fluent/configs.d/openshift/output-applications.conf /etc/fluent/configs.d/dynamic/output-remote-syslog.conf | artifact_out || :
artifact_log ping $myhost from $mypod
oc exec $mypod -- ping $myhost -c 3 | artifact_out || :

# wait for the precise formatted logs are found in /var/log/messages
# os::cmd::try_until_text "sudo egrep \"^[0-6],[0-9]*,\" /var/log/messages" "[0-6],[0-9]*,.*" $MUX_WAIT_TIME
# sudo egrep \"^[0-6],[0-9]*,\" /var/log/messages | tail -n 5 | artifact_out || :

artifact_log docker info
docker info | artifact_out || :

mymessage="rsyslogTestMessage-"$( date +%Y%m%d-%H%M%S )
ident=rsyslogTestTag$( openssl rand -hex 16 )
logger -i -p local1.err -t $ident $mymessage
es_pod=$( get_es_pod es )
es_ops_pod=$( get_es_pod es-ops )
es_ops_pod=${es_ops_pod:-$es_pod}
qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'$ident'"}}}'
rc=0
if os::cmd::try_until_text "curl_es ${es_ops_pod} /.operations.*/_count -X POST -d '$qs' | get_count_from_json" '^1$' $MUX_WAIT_TIME; then
    artifact_log good - found $mymessage
else
    artifact_log failed - not found $mymessage
    rc=1
fi
os::cmd::try_until_success "sudo egrep -q '${mymessage}\$' /var/log/messages" $MUX_WAIT_TIME
artifact_log Log test message by logger: $mymessage
sudo egrep "${mymessage}$" /var/log/messages 2>&1 | artifact_out || :
if [ $rc -eq 1 ] ; then
    exit 1
fi

mymessage="testKibanaMessage-"$( date +%Y%m%d-%H%M%S )
add_test_message $mymessage
fullmsg="GET /${mymessage} 404 "
qs='{"query":{"bool":{"filter":{"match_phrase":{"message":"'"${fullmsg}"'"}},"must":{"term":{"kubernetes.container_name":"kibana"}}}}}'
case "${LOGGING_NS}" in
default|openshift|openshift-*) logging_index=".operations.*" ; es_pod=$es_ops_pod ;;
*) logging_index="project.${LOGGING_NS}.*" ;;
esac
rc=0
if os::cmd::try_until_text "curl_es ${es_pod} /${logging_index}/_count -X POST -d '$qs' | get_count_from_json" 1 $MUX_WAIT_TIME; then
    artifact_log good - found $mymessage
else
    artifact_log failed - not found $mymessage
    rc=1
fi
os::cmd::try_until_success "sudo egrep -q '${mymessage}' /var/log/messages" $MUX_WAIT_TIME
artifact_log Log test message by kibana: $mymessage
sudo egrep "/${mymessage}" /var/log/messages 2>&1 | artifact_out || :
if [ $rc -eq 1 ] ; then
    exit 1
fi

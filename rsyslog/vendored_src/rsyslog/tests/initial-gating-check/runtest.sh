#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/rsyslog/Sanity/various-simple-checks
#   Description: initial-gating-check
#   Author: Jiri Vymazal <jvymazal@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2017 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="rsyslog"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlLog "Import RpmSnapshot library"
        rlRun "rlImport distribution/RpmSnapshot"
        rlFileBackup "/var/log/messages"
        rlFileBackup "/etc/rsyslog.conf"
        rlRun "cp /etc/rsyslog.conf ."
        rlServiceStop "rsyslog"
        rlServiceStart "rsyslog"
    rlPhaseEnd

    rlPhaseStartTest "BZ#1399555"
        rlAssertGrep "rsyslogd" /var/log/messages
        rlAssertNotGrep "liblogging" /var/log/messages
    rlPhaseEnd

    rlPhaseStartTest "BZ#1399562"
        rlServiceStop "rsyslog"
        rlServiceStart "rsyslog"
        rlAssertNotGrep "rsyslogd.*segfault" /var/log/messages
    rlPhaseEnd

    rlPhaseStartTest "BZ#1399652"
        rlServiceStop "rsyslog"
        rlServiceStart "rsyslog"
          [ ! -f "/var/run/rsyslogd.pid" ] && rlFail "/var/run/rsyslogd.pid file not found"
          [ -f "/var/run/syslogd.pid" ] && rlFail "/var/run/syslogd.pid file found"
        pid_of=`pidof rsyslogd`
        rlLogInfo "PID of rsyslogd: $pid_of"
        pid_file=`cat /var/run/syslogd.pid`
        rlLogInfo "PID in pidfile: $pid_file"
        # dummy check
        [ $pid_of -ne $pid_file ] && rlFail "PIDs are not the same"
    rlPhaseEnd

    rlPhaseStartTest "BZ#1410630"
        rlRun "rsyslogd -N 1" 0 "\"rsyslogd -N 1\" should return 0"
        rlLogInfo "set invalid configuration "
        echo ":msg, eregex, \"^(Starting|Stopping) user-[0-9]+\.slice\"           stop" >> /etc/rsyslog.conf
        rlRun "rsyslogd -N 1" 1 "\"rsyslogd -N 1\" should return 1"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlServiceStop "rsyslog"
	sleep 2
        rlFileRestore "/var/log/messages"
        rlFileRestore "/etc/rsyslog.conf"
        rlServiceStart "rsyslog"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

#!/bin/sh
# Wrapper to start rsyslog.d with appropriate sysconfig options


source /etc/sysconfig/rsyslog
exec /usr/sbin/rsyslogd -n $SYSLOGD_OPTIONS

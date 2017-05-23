#!/bin/bash

if [[ $VERBOSE ]]; then
  set -ex
  fluentdargs="-vv"
else
  set -e
  fluentdargs=
fi

docker_uses_journal() {
    # need to be able to handle cases like
    # OPTIONS='--log-driver=json-file ....' # or use --log-driver=journald
    grep -q "^OPTIONS='[^']*--log-driver=journald" /etc/sysconfig/docker
}

if [ "${USE_JOURNAL:-}" != false ] ; then
    if [ -z "${JOURNAL_SOURCE:-}" ] ; then
        if [ -d /var/log/journal ] ; then
            export JOURNAL_SOURCE=/var/log/journal
        else
            export JOURNAL_SOURCE=/run/log/journal
        fi
    fi
    if [ -z "${USE_JOURNAL:-}" ] ; then
        if docker_uses_journal ; then
            export USE_JOURNAL=true
        else
            export USE_JOURNAL=false
        fi
    fi
fi

IPADDR4=`/usr/sbin/ip -4 addr show dev eth0 | grep inet | sed -e "s/[ \t]*inet \([0-9.]*\).*/\1/"`
IPADDR6=`/usr/sbin/ip -6 addr show dev eth0 | grep inet6 | sed "s/[ \t]*inet6 \([a-f0-9:]*\).*/\1/"`
export IPADDR4 IPADDR6

BUFFER_SIZE_LIMIT=${BUFFER_SIZE_LIMIT:-1048576}
FLUENTD_CPU_LIMIT=${FLUENTD_CPU_LIMIT:-100m}
FLUENTD_MEMORY_LIMIT=${FLUENTD_MEMORY_LIMIT:-512Mi}

CFG_DIR=/etc/fluent/configs.d
ruby generate_throttle_configs.rb

TOTAL_MEMORY_LIMIT=`echo $FLUENTD_MEMORY_LIMIT |  sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc`
BUFFER_SIZE_LIMIT=`echo $BUFFER_SIZE_LIMIT |  sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc`
if [ $BUFFER_SIZE_LIMIT -eq 0 ]; then
    BUFFER_SIZE_LIMIT=1048576
fi

DIV=1
if [ "$ES_HOST" != "$OPS_HOST" ] || [ "$ES_PORT" != "$OPS_PORT" ] ; then
    # using ops cluster
    DIV=`expr $DIV \* 2`
fi

# MEMORY_LIMIT per buffer
MEMORY_LIMIT=`expr $TOTAL_MEMORY_LIMIT / $DIV`
BUFFER_QUEUE_LIMIT=`expr $MEMORY_LIMIT / $BUFFER_SIZE_LIMIT`
if [ $BUFFER_QUEUE_LIMIT -eq 0 ]; then
    BUFFER_QUEUE_LIMIT=1024
fi
export BUFFER_QUEUE_LIMIT BUFFER_SIZE_LIMIT

OPS_COPY_HOST="${OPS_COPY_HOST:-$ES_COPY_HOST}"
OPS_COPY_PORT="${OPS_COPY_PORT:-$ES_COPY_PORT}"
OPS_COPY_SCHEME="${OPS_COPY_SCHEME:-$ES_COPY_SCHEME}"
OPS_COPY_CLIENT_CERT="${OPS_COPY_CLIENT_CERT:-$ES_COPY_CLIENT_CERT}"
OPS_COPY_CLIENT_KEY="${OPS_COPY_CLIENT_KEY:-$ES_COPY_CLIENT_KEY}"
OPS_COPY_CA="${OPS_COPY_CA:-$ES_COPY_CA}"
OPS_COPY_USERNAME="${OPS_COPY_USERNAME:-$ES_COPY_USERNAME}"
OPS_COPY_PASSWORD="${OPS_COPY_PASSWORD:-$ES_COPY_PASSWORD}"
export OPS_COPY_HOST OPS_COPY_PORT OPS_COPY_SCHEME OPS_COPY_CLIENT_CERT \
       OPS_COPY_CLIENT_KEY OPS_COPY_CA OPS_COPY_USERNAME OPS_COPY_PASSWORD

if [ "$ES_COPY" = "true" ] ; then
    # user wants to split the output of fluentd into two different elasticsearch
    # user will provide the necessary COPY environment variables as above
    cp $CFG_DIR/{openshift,dynamic}/es-copy-config.conf
    cp $CFG_DIR/{openshift,dynamic}/es-ops-copy-config.conf
else
    # create empty files for the ES copy config
    echo > $CFG_DIR/dynamic/es-copy-config.conf
    echo > $CFG_DIR/dynamic/es-ops-copy-config.conf
fi

# http://docs.fluentd.org/v0.12/articles/monitoring
if [ "${ENABLE_MONITOR_AGENT:-}" = true ] ; then
    cp $CFG_DIR/input-pre-monitor.conf $CFG_DIR/openshift
    # copy any user defined files, possibly overwriting the standard ones
    if [ -f $CFG_DIR/user/input-pre-monitor.conf ] ; then
        cp -f $CFG_DIR/user/input-pre-monitor.conf $CFG_DIR/openshift
    fi
else
    rm -f $CFG_DIR/openshift/input-pre-monitor.conf
fi

# http://docs.fluentd.org/v0.12/articles/monitoring#debug-port
if [ "${ENABLE_DEBUG_AGENT:-}" = true ] ; then
    cp $CFG_DIR/input-pre-debug.conf $CFG_DIR/openshift
    # copy any user defined files, possibly overwriting the standard ones
    if [ -f $CFG_DIR/user/input-pre-debug.conf ] ; then
        cp -f $CFG_DIR/user/input-pre-debug.conf $CFG_DIR/openshift
    fi
else
    rm -f $CFG_DIR/openshift/input-pre-debug.conf
fi

# bug https://bugzilla.redhat.com/show_bug.cgi?id=1437952
# pods unable to be terminated because fluentd has them busy
echo "umounts of dead containers will fail. Ignoring..."
umount /var/lib/docker/containers/*/shm || :

if [[ $DEBUG ]] ; then
    exec fluentd $fluentdargs > /var/log/fluentd.log 2>&1
else
    exec fluentd $fluentdargs
fi

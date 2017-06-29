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

BUFFER_SIZE_LIMIT=${BUFFER_SIZE_LIMIT:-16777216}

CFG_DIR=/etc/fluent/configs.d
ruby generate_throttle_configs.rb

# fluentd usually has 2 outputs.
NUM_OUTPUTS=2
if [ "$ES_COPY" = "true" ]; then
    NUM_OUTPUTS=`expr $NUM_OUTPUTS \* 2`
fi

# If FILE_BUFFER_PATH exists and it is not a directory, mkdir fails with the error.
FILE_BUFFER_PATH=/var/lib/fluentd
mkdir -p $FILE_BUFFER_PATH

# Get the available disk size; use 1/4 of it
DF_LIMIT=$(df -B1 $FILE_BUFFER_PATH | grep -v Filesystem | awk '{print $2}')
DF_LIMIT=${DF_LIMIT:-0}
DF_LIMIT=$(expr $DF_LIMIT / 4) || :
if [ $DF_LIMIT -eq 0 ]; then
    echo "ERROR: No disk space is available for file buffer in $FILE_BUFFER_PATH."
    exit 1
fi
# Determine final total given the number of outputs we have.
TOTAL_LIMIT=$(echo ${FILE_BUFFER_LIMIT:-2Gi} | sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc) || :
if [ $TOTAL_LIMIT -le 0 ]; then
    echo "ERROR: Invalid file buffer limit ($FILE_BUFFER_LIMIT) is given.  Failed to convert to bytes."
    exit 1
fi
TOTAL_LIMIT=$(expr $TOTAL_LIMIT \* $NUM_OUTPUTS) || :
if [ $DF_LIMIT -lt $TOTAL_LIMIT ]; then
    echo "WARNING: Available disk space ($DF_LIMIT bytes) is less than the user specified file buffer limit ($FILE_BUFFER_LIMIT times $NUM_OUTPUTS)."
    TOTAL_LIMIT=$DF_LIMIT
fi

BUFFER_SIZE_LIMIT=$(echo $BUFFER_SIZE_LIMIT |  sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc)
BUFFER_SIZE_LIMIT=${BUFFER_SIZE_LIMIT:-16777216}

# TOTAL_BUFFER_SIZE_LIMIT per buffer
TOTAL_BUFFER_SIZE_LIMIT=$(expr $TOTAL_LIMIT / $NUM_OUTPUTS) || :
if [ -z $TOTAL_BUFFER_SIZE_LIMIT -o $TOTAL_BUFFER_SIZE_LIMIT -eq 0 ]; then
    echo "ERROR: Calculated TOTAL_BUFFER_SIZE_LIMIT is 0. TOTAL_LIMIT $TOTAL_LIMIT is too small compared to NUM_OUTPUTS $NUM_OUTPUTS. Please increase FILE_BUFFER_LIMIT $FILE_BUFFER_LIMIT and/or the volume size of $FILE_BUFFER_PATH."
    exit 1
fi
BUFFER_QUEUE_LIMIT=$(expr $TOTAL_BUFFER_SIZE_LIMIT / $BUFFER_SIZE_LIMIT) || :
if [ -z $BUFFER_QUEUE_LIMIT -o $BUFFER_QUEUE_LIMIT -eq 0 ]; then
    echo "ERROR: Calculated BUFFER_QUEUE_LIMIT is 0. TOTAL_BUFFER_SIZE_LIMIT $TOTAL_BUFFER_SIZE_LIMIT is too small compared to BUFFER_SIZE_LIMIT $BUFFER_SIZE_LIMIT. Please increase FILE_BUFFER_LIMIT $FILE_BUFFER_LIMIT and/or the volume size of $FILE_BUFFER_PATH."
    exit 1
fi
export BUFFER_QUEUE_LIMIT BUFFER_SIZE_LIMIT
export K8S_FILTER_REMOVE_KEYS

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

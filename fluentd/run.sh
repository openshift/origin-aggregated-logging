#!/bin/bash

if [[ $VERBOSE ]]; then
  set -ex
  fluentdargs="-vv"
  echo ">>>>>> ENVIRONMENT VARS <<<<<"
  env | sort
  echo ">>>>>>>>>>>>><<<<<<<<<<<<<<<<"
else
  set -e
  fluentdargs=
fi

docker_uses_journal() {
    # need to be able to handle cases like
    # OPTIONS='--log-driver=json-file ....' # or use --log-driver=journald
    # if "log-driver" is set in /etc/docker/daemon.json, assume that it is
    # authoritative
    # otherwise, look for /etc/sysconfig/docker
    # also note the unintuitive logic - in this case, a 0 return means true, and a 1
    # return means false
    if grep -q '^[^#].*"log-driver":' /etc/docker/daemon.json 2> /dev/null ; then
        if grep -q '^[^#].*"log-driver":.*journald' /etc/docker/daemon.json 2> /dev/null ; then
            return 0
        fi
    elif grep -q "^OPTIONS='[^']*--log-driver=journald" /etc/sysconfig/docker 2> /dev/null ; then
        return 0
    fi
    return 1
}

if [ "${MUX_ALLOW_EXTERNAL:-}" = "true" ] ; then
    # mux service implies mux
    export USE_MUX=true
fi

if [ -z "${USE_MUX:-}" -o "${USE_MUX:-}" = "false" ] ; then
    if [ -z "${USE_JOURNAL:-}" -o "${USE_JOURNAL:-}" = true ] ; then
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
else
    # mux requires USE_JOURNAL=true so that the k8s meta plugin will look
    # for CONTAINER_NAME instead of the kubernetes.var.log.containers.* tag
    export USE_JOURNAL=true
fi

IPADDR4=`/usr/sbin/ip -4 addr show dev eth0 | grep inet | sed -e "s/[ \t]*inet \([0-9.]*\).*/\1/"`
IPADDR6=`/usr/sbin/ip -6 addr show dev eth0 | grep inet6 | sed "s/[ \t]*inet6 \([a-f0-9:]*\).*/\1/"`
export IPADDR4 IPADDR6

BUFFER_SIZE_LIMIT=${BUFFER_SIZE_LIMIT:-1048576}
FLUENTD_MEMORY_LIMIT=${FLUENTD_MEMORY_LIMIT:-512Mi}
MUX_MEMORY_LIMIT=${MUX_MEMORY_LIMIT:-2Gi}

CFG_DIR=/etc/fluent/configs.d
if [ "${USE_MUX:-}" = "true" ] ; then
    # copy our standard mux configs to the openshift dir
    cp $CFG_DIR/input-*-mux.conf $CFG_DIR/openshift
    # copy any user defined files, possibly overwriting the standard ones
    for file in $CFG_DIR/user/input-*-mux.conf ; do
        if [ -f "$file" ] ; then
            cp -f $file $CFG_DIR/openshift
        fi
    done
    rm -f $CFG_DIR/dynamic/input-docker-* $CFG_DIR/dynamic/input-syslog-*
    if [ "${MUX_ALLOW_EXTERNAL:-}" = "true" ] ; then
        cp $CFG_DIR/mux-post-input*.conf $CFG_DIR/filter-*-mux.conf $CFG_DIR/openshift
        # copy any user defined files, possibly overwriting the standard ones
        for file in $CFG_DIR/user/mux-post-input*.conf $CFG_DIR/user/filter-*-mux.conf ; do
            if [ -f "$file" ] ; then
                cp -f $file $CFG_DIR/openshift
            fi
        done
    else
        rm -f $CFG_DIR/openshift/mux-post-input*.conf $CFG_DIR/openshift/filter-*-mux.conf
    fi
else
    ruby generate_throttle_configs.rb
    rm -f $CFG_DIR/openshift/*mux*.conf
fi

if [ "${USE_MUX_CLIENT:-}" = "true" ] ; then
    cp $CFG_DIR/filter-pre-mux-client.conf $CFG_DIR/openshift
    # copy any user defined files, possibly overwriting the standard ones
    if [ -f $CFG_DIR/user/filter-pre-mux-client.conf ] ; then
        cp -f $CFG_DIR/user/filter-pre-mux-client.conf $CFG_DIR/openshift
    fi
    # rm k8s meta plugin - do not hit the API server
    rm $CFG_DIR/openshift/filter-k8s-meta.conf
    touch $CFG_DIR/openshift/filter-k8s-meta.conf
else
    rm -f $CFG_DIR/openshift/filter-pre-mux-client.conf
fi

# How many outputs?
if [ "${USE_MUX_CLIENT:-}" = "true" ] ; then
    # mux client has just one output.
    DIV=1
else
    # fluend usually has 2 putputs.
    DIV=2
    if [ "$ES_COPY" = "true" ]; then
        DIV=`expr $DIV \* 2`
    fi
fi

if [ "$BUFFER_TYPE" = "file" -a -z "$FILE_BUFFER_PATH" ]; then
    echo "ERROR: BUFFER_TYPE is set to file but FILE_BUFFER_PATH is empty.  Please specify a FILE_BUFFER_PATH.  Exiting."
    exit 1
fi

FILE_BUFFER_PATH_ES=""
FILE_BUFFER_PATH_ESOPS=""
FILE_BUFFER_PATH_ES_COPY=""
FILE_BUFFER_PATH_ESOPS_COPY=""
# Default buffer_type: file if FILE_BUFFER_PATH is specified.
if [ "${BUFFER_TYPE:-}" = "file" ]; then
    if [ ! -d $FILE_BUFFER_PATH ]; then
        mkdir -p $FILE_BUFFER_PATH
    fi
    # Get the available disk size; use 1/4 of it
    DF_LIMIT=$(df -B1 $FILE_BUFFER_PATH | grep -v Filesystem | awk '{print $2}')
    DF_LIMIT=${DF_LIMIT:-0}
    DF_LIMIT=$(expr $DF_LIMIT / 4) || :
    if [ $DF_LIMIT -eq 0 ]; then
        echo "ERROR: No disk space is available for file buffer in $FILE_BUFFER_PATH.  Using memory buffer."
        exit 1
    fi
    # Given buffer limit per output
    TOTAL_LIMIT=$(echo ${FILE_BUFFER_LIMIT:-0} | sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc) || :
    # In total
    TOTAL_LIMIT=$(expr $TOTAL_LIMIT \* $DIV) || :
    if [ $TOTAL_LIMIT -le 0 ]; then
        echo "ERROR: Invalid file buffer limit ($FILE_BUFFER_LIMIT) is given.  Failed to convert to bytes."
        exit 1
    fi
    # Available disk space is less than the specified size.
    if [ $DF_LIMIT -lt $TOTAL_LIMIT ]; then
        echo "WARNING: Available disk space ($DF_LIMIT bytes) is less than the user specified file buffer limit ($FILE_BUFFER_LIMIT)."
        TOTAL_LIMIT=$DF_LIMIT
    fi
    FILE_BUFFER_PATH_ES=${FILE_BUFFER_PATH}/es
    FILE_BUFFER_PATH_ESOPS=${FILE_BUFFER_PATH}/esops
    FILE_BUFFER_PATH_ES_COPY=${FILE_BUFFER_PATH}/escopy
    FILE_BUFFER_PATH_ESOPS_COPY=${FILE_BUFFER_PATH}/esopscopy
else
    BUFFER_TYPE="memory"
fi
if [ "$BUFFER_TYPE" = "memory" ] ; then
    if [ "${USE_MUX:-}" = "true" ] ; then
        TOTAL_LIMIT=$(echo $MUX_MEMORY_LIMIT | sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc) || :
    else
        TOTAL_LIMIT=$(echo $FLUENTD_MEMORY_LIMIT | sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc) || :
    fi
    # Use 75% of the avialble memory
    TOTAL_LIMIT=$(expr $(expr $TOTAL_LIMIT \* 3) / 4) || :
fi
if [ -z $TOTAL_LIMIT -o $TOTAL_LIMIT -eq 0 ]; then
    if [ "$USE_MUX" = "true" ]; then
        # 75 % of 2G
        TOTAL_LIMIT=1610612736
    else
        # 75 % of 512M
        TOTAL_LIMIT=402653184
    fi
fi

BUFFER_SIZE_LIMIT=$(echo $BUFFER_SIZE_LIMIT |  sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc)
BUFFER_SIZE_LIMIT=${BUFFER_SIZE_LIMIT:-1048576}

# TOTAL_BUFFER_SIZE_LIMIT per buffer
TOTAL_BUFFER_SIZE_LIMIT=$(expr $TOTAL_LIMIT / $DIV) || :
BUFFER_QUEUE_LIMIT=$(expr $TOTAL_BUFFER_SIZE_LIMIT / $BUFFER_SIZE_LIMIT) || :
if [ -z $BUFFER_QUEUE_LIMIT -o $BUFFER_QUEUE_LIMIT -eq 0 ]; then
    BUFFER_QUEUE_LIMIT=256
fi
export BUFFER_QUEUE_LIMIT BUFFER_SIZE_LIMIT BUFFER_TYPE
export FILE_BUFFER_PATH_ES FILE_BUFFER_PATH_ESOPS FILE_BUFFER_PATH_ES_COPY FILE_BUFFER_PATH_ESOPS_COPY

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

# When USE_MUX_CLIENT is true, logs are forwarded to MUX; COPY won't work with it.
if [ "$ES_COPY" = "true" -a "${USE_MUX_CLIENT:-}" != "true" ] ; then
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
if [ "${USE_MUX:-}" = "true" ] ; then
    : # skip umount
else
    echo "umounts of dead containers will fail. Ignoring..."
    umount /var/lib/docker/containers/*/shm || :
fi

if [[ $DEBUG ]] ; then
    exec fluentd $fluentdargs > /var/log/fluentd.log 2>&1
else
    exec fluentd $fluentdargs
fi

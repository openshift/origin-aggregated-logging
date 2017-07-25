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
MUX_CPU_LIMIT=${MUX_CPU_LIMIT:-500m}
MUX_MEMORY_LIMIT=${MUX_MEMORY_LIMIT:-2Gi}
FLUENTD_CPU_LIMIT=${FLUENTD_CPU_LIMIT:-100m}
FLUENTD_MEMORY_LIMIT=${FLUENTD_MEMORY_LIMIT:-512Mi}

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
    # assume mux doesn't actually read from the journal file
    if [ "${USE_JOURNAL:-}" = "true" ] ; then
        # have output plugins handle back pressure
        # if you want the old behavior to be forced anyway, set env
        # BUFFER_QUEUE_FULL_ACTION=exception
        export BUFFER_QUEUE_FULL_ACTION=${BUFFER_QUEUE_FULL_ACTION:-block}
    fi
fi

# this is the list of keys to remove when the record is transformed from the raw systemd journald
# output to the viaq data model format
K8S_FILTER_REMOVE_KEYS="log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID"

if [ -n "${MUX_CLIENT_MODE:-}" -o "${USE_MUX_CLIENT:-}" = "true" ] ; then
    mux_client_filename=filter-pre-mux-client.conf
    if [ "${MUX_CLIENT_MODE:-}" = full_no_k8s_meta ] ; then
        mux_client_filename=output-pre-mux-client.conf
        # do not remove the CONTAINER_ fields - pass them through to mux
        # sed assumes CONTAINER_ fields are not first nor last fields in list
        K8S_FILTER_REMOVE_KEYS=$( echo $K8S_FILTER_REMOVE_KEYS | \
                                  sed -e 's/,CONTAINER_NAME,/,/g' -e 's/,CONTAINER_ID_FULL,/,/g' )
    fi
    cp $CFG_DIR/filter-pre-mux-client.conf $CFG_DIR/openshift/$mux_client_filename
    # copy any user defined files, possibly overwriting the standard ones
    if [ -f $CFG_DIR/user/filter-pre-mux-client.conf ] ; then
        cp -f $CFG_DIR/user/filter-pre-mux-client.conf $CFG_DIR/openshift/$mux_client_filename
    fi
    # rm k8s meta plugin - do not hit the API server
    if [ "${MUX_CLIENT_MODE:-}" = full_no_k8s_meta -o "${USE_MUX_CLIENT:-}" = "true" ] ; then
        rm $CFG_DIR/openshift/filter-k8s-meta.conf
        touch $CFG_DIR/openshift/filter-k8s-meta.conf
    fi
else
    rm -f $CFG_DIR/openshift/filter-pre-mux-client.conf $CFG_DIR/openshift/output-pre-mux-client.conf
fi
export K8S_FILTER_REMOVE_KEYS

if [ "${USE_MUX:-}" = "true" ] ; then
    TOTAL_MEMORY_LIMIT=`echo $MUX_MEMORY_LIMIT |  sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc`
else
    TOTAL_MEMORY_LIMIT=`echo $FLUENTD_MEMORY_LIMIT |  sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc`
fi
BUFFER_SIZE_LIMIT=`echo $BUFFER_SIZE_LIMIT |  sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc`
if [ $BUFFER_SIZE_LIMIT -eq 0 ]; then
    BUFFER_SIZE_LIMIT=1048576
fi

DIV=1
if [ "$ES_HOST" != "$OPS_HOST" ] || [ "$ES_PORT" != "$OPS_PORT" ] ; then
    # using ops cluster
    DIV=`expr $DIV \* 2`
fi
if [ -n "${MUX_CLIENT_MODE:-}" -o "${USE_MUX_CLIENT:-}" = "true" ] ; then
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

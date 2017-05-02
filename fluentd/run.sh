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

if [ "${MUX_ALLOW_EXTERNAL:-}" = "true" ] ; then
    # mux service implies mux
    export USE_MUX=true
fi

if [ "${USE_MUX:-}" != "true" ] ; then
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
else
    # mux requires USE_JOURNAL=true so that the k8s meta plugin will look
    # for CONTAINER_NAME instead of the kubernetes.var.log.containers.* tag
    export USE_JOURNAL=true
fi

IPADDR4=`/usr/sbin/ip -4 addr show dev eth0 | grep inet | sed -e "s/[ \t]*inet \([0-9.]*\).*/\1/"`
IPADDR6=`/usr/sbin/ip -6 addr show dev eth0 | grep inet6 | sed "s/[ \t]*inet6 \([a-f0-9:]*\).*/\1/"`
export IPADDR4 IPADDR6

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
else
    rm -f $CFG_DIR/openshift/filter-pre-mux-client.conf
fi

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

if [[ $DEBUG ]] ; then
    exec fluentd $fluentdargs > /var/log/fluentd.log 2>&1
else
    exec fluentd $fluentdargs
fi

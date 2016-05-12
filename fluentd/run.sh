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
    if grep -q "^OPTIONS='[^']*--log-driver=journald" /etc/sysconfig/docker ; then
        export USE_JOURNAL=true
    else
        export USE_JOURNAL=false
    fi
    # the problem with this method is - how do we know that the information in this
    # log message is still applicable for the currently running docker?
    # if docker is using journal, the journal entries for containers will
    # come from _COMM=docker-current, and will have a _CMDLINE like this
    # _CMDLINE=/usr/bin/docker-current daemon --exec-opt native.cgroupdriver=systemd --selinux-enabled --log-driver=journald ...
    # test -d $JOURNAL_SOURCE && \
    #     journalctl -o export -n1 --all -D $JOURNAL_SOURCE _COMM=docker-current | \
    #         grep -q '_CMDLINE=.*--log-driver=journald' 2> /dev/null
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

CFG_DIR=/etc/fluent/configs.d
ruby generate_throttle_configs.rb

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


fluentd $fluentdargs

#!/bin/bash

if [[ $VERBOSE ]]; then
  set -ex
  fluentdargs="-vv"
else
  set -e
  fluentdargs=  
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

CFG_IN_DIR=/etc/fluent/configs.d/input
CFG_OUT_DIR=/etc/fluent/configs.d/output

mkdir -p $CFG_IN_DIR/docker
mkdir -p $CFG_IN_DIR/syslog

ruby generate_throttle_configs.rb

if [ "$ES_COPY" = "true" ] ; then
    # user wants to split the output of fluentd into two different elasticsearch
    # user will provide the necessary COPY environment variables as above
    cp $HOME/fluentd_es_copy_config.conf $HOME/fluentd_es_ops_copy_config.conf $CFG_OUT_DIR
else
    # create empty files for the ES copy config
    rm -f $CFG_OUT_DIR/fluentd_es_copy_config.conf $CFG_OUT_DIR/fluentd_es_ops_copy_config.conf
    touch $CFG_OUT_DIR/fluentd_es_copy_config.conf $CFG_OUT_DIR/fluentd_es_ops_copy_config.conf
fi


fluentd $fluentdargs

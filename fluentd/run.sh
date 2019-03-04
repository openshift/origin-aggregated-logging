#!/bin/bash

export MERGE_JSON_LOG=${MERGE_JSON_LOG:-true}
CFG_DIR=/etc/fluent/configs.d
ENABLE_PROMETHEUS_ENDPOINT=${ENABLE_PROMETHEUS_ENDPOINT:-"true"}
OCP_OPERATIONS_PROJECTS=${OCP_OPERATIONS_PROJECTS:-"default openshift openshift- kube-"}
OCP_FLUENTD_TAGS=""
for p in ${OCP_OPERATIONS_PROJECTS}; do
    if [[ "${p}" == *- ]] ; then
      p="${p}*"
    fi
    OCP_FLUENTD_TAGS+=" **_${p}_**"
done
ocp_fluentd_files=$( grep -l %OCP_FLUENTD_TAGS% ${CFG_DIR}/* ${CFG_DIR}/*/* 2> /dev/null || : )
for file in ${ocp_fluentd_files} ; do
    sed -i -e "s/%OCP_FLUENTD_TAGS%/${OCP_FLUENTD_TAGS}/" $file
done

echo "============================="
echo "Fluentd logs have been redirected to: $LOGGING_FILE_PATH"
echo "If you want to print out the logs, use command:"
echo "oc exec <pod_name> -- logs"
echo "============================="

dirname=$( dirname $LOGGING_FILE_PATH )
if [ ! -d $dirname ] ; then
    mkdir -p $dirname
fi
touch $LOGGING_FILE_PATH; exec >> $LOGGING_FILE_PATH 2>&1
fluentdargs="--no-supervisor -o $LOGGING_FILE_PATH --log-rotate-age $LOGGING_FILE_AGE --log-rotate-size $LOGGING_FILE_SIZE"
# find the sniffer class file
sniffer=$( gem contents fluent-plugin-elasticsearch|grep elasticsearch_simple_sniffer.rb )
if [ -z "$sniffer" ] ; then
    sniffer=$( rpm -ql rubygem-fluent-plugin-elasticsearch|grep elasticsearch_simple_sniffer.rb )
fi
if [ -n "$sniffer" -a -f "$sniffer" ] ; then
    fluentdargs="$fluentdargs -r $sniffer"
fi

if [[ $VERBOSE ]]; then
  set -ex
  fluentdargs="$fluentdargs -vv --log-event-verbose"
  echo ">>>>>> ENVIRONMENT VARS <<<<<"
  env | sort
  echo ">>>>>>>>>>>>><<<<<<<<<<<<<<<<"
else
  set -e
  fluentdargs="$fluentdargs -q --suppress-config-dump"
fi

issue_deprecation_warnings() {
    : # none at the moment
}

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
    elif grep -q "^OPTIONS='[^']*--log-driver[   =][     ]*journald" /etc/sysconfig/docker 2> /dev/null ; then
        return 0
    fi
    return 1
}

if [ -z "${USE_MUX:-}" -o "${USE_MUX:-}" = "false" ] ; then
    if [ -z "${JOURNAL_SOURCE:-}" ] ; then
        if [ -d /var/log/journal ] ; then
            export JOURNAL_SOURCE=/var/log/journal
        else
            export JOURNAL_SOURCE=/run/log/journal
        fi
    fi
    if docker_uses_journal ; then
        export USE_JOURNAL=true
    else
        export USE_JOURNAL=false
    fi
else
    # mux requires USE_JOURNAL=true so that the k8s meta plugin will look
    # for CONTAINER_NAME instead of the kubernetes.var.log.containers.* tag
    export USE_JOURNAL=true
fi

if [ ! -d /etc/fluent/muxkeys ]; then
    unset MUX_CLIENT_MODE
fi

IPADDR4=`/usr/sbin/ip -4 addr show dev eth0 | grep inet | sed -e "s/[ \t]*inet \([0-9.]*\).*/\1/"`
IPADDR6=`/usr/sbin/ip -6 addr show dev eth0 | grep inet6 | sed "s/[ \t]*inet6 \([a-f0-9:]*\).*/\1/"`
export IPADDR4 IPADDR6

BUFFER_SIZE_LIMIT=${BUFFER_SIZE_LIMIT:-16777216}

# Check the existing main fluent.conf has the @OUTPUT label
# If it exists, we could use the label and take advantage.
# If not, give up one output tag per plugin for now.
output_label=$( egrep "<label @OUTPUT>" $CFG_DIR/../fluent.conf || : )

if [ "${USE_MUX:-}" = "true" ] ; then
    # copy our standard mux configs to the openshift dir
    cp $CFG_DIR/input-*-mux.conf $CFG_DIR/filter-*-mux.conf $CFG_DIR/openshift
    # copy any user defined files, possibly overwriting the standard ones
    for file in $CFG_DIR/user/input-*-mux.conf $CFG_DIR/user/filter-*-mux.conf ; do
        if [ -f "$file" ] ; then
            cp -f $file $CFG_DIR/openshift
        fi
    done
    rm -f $CFG_DIR/dynamic/input-docker-* $CFG_DIR/dynamic/input-syslog-*
    # disable systemd input
    rm -f $CFG_DIR/openshift/input-pre-systemd.conf
    touch $CFG_DIR/openshift/input-pre-systemd.conf
    # mux is a normalizer
    export PIPELINE_TYPE=normalizer
else
    ruby generate_throttle_configs.rb
    rm -f $CFG_DIR/openshift/*mux*.conf
    # have output plugins handle back pressure
    # if you want the old behavior to be forced anyway, set env
    # BUFFER_QUEUE_FULL_ACTION=exception
    export BUFFER_QUEUE_FULL_ACTION=${BUFFER_QUEUE_FULL_ACTION:-block}
fi

# this is the list of keys to remove when the record is transformed from the raw systemd journald
# output to the viaq data model format
K8S_FILTER_REMOVE_KEYS="log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID"

if [ -n "${MUX_CLIENT_MODE:-}" ] ; then
    if [ "${MUX_CLIENT_MODE:-}" = maximal ] ; then
        # do not remove the CONTAINER_ fields - pass them through to mux
        # sed assumes CONTAINER_ fields are neither first nor last fields in list
        K8S_FILTER_REMOVE_KEYS=$( echo $K8S_FILTER_REMOVE_KEYS | \
                                  sed -e 's/,CONTAINER_NAME,/,/g' -e 's/,CONTAINER_ID_FULL,/,/g' )
        # tell the viaq filter not to construct an elasticsearch index name
        # for project because we have no kubernetes metadata yet
    elif [ "${MUX_CLIENT_MODE:-}" = minimal ] ; then
        # retag container logs with .raw suffix so mux server will know it has to process
        cp -f $CFG_DIR/filter-pre-mux-client-retag-raw.conf $CFG_DIR/openshift/filter-pre-mux-client-retag-raw.conf
        if [ -z "${output_label}" ] ; then
            # the above relies on having an output label - if there is no output label, rely
            # on the fact that the input plugins all send their input directly to the
            # @INGRESS label, rather than simply falling through to the next line
            # in fluent.conf - add an input-post-output.conf which has the @OUTPUT
            # label
            cp -f $CFG_DIR/input-post-output.conf $CFG_DIR/openshift/input-post-output.conf
        fi
    fi
    cp $CFG_DIR/filter-pre-mux-client.conf $CFG_DIR/openshift/output-pre-mux-client.conf
    # copy any user defined files, possibly overwriting the standard ones
    if [ -f $CFG_DIR/user/filter-pre-mux-client.conf ] ; then
        cp -f $CFG_DIR/user/filter-pre-mux-client.conf $CFG_DIR/openshift/output-pre-mux-client.conf
    fi
    # rm k8s meta plugin - do not hit the API server - just do json parsing
    if [ "${MUX_CLIENT_MODE:-}" = maximal ] ; then
        cp -f $CFG_DIR/filter-parse-json-field.conf $CFG_DIR/openshift/filter-k8s-meta.conf
    fi
    # mux clients do not create elasticsearch index names
    ENABLE_ES_INDEX_NAME=false
else
    rm -f $CFG_DIR/openshift/filter-pre-mux-client.conf $CFG_DIR/openshift/output-pre-mux-client.conf
fi
export K8S_FILTER_REMOVE_KEYS ENABLE_ES_INDEX_NAME

if [ -z $ES_HOST ]; then
    echo "ERROR: Environment variable ES_HOST for Elasticsearch host name is not set."
    exit 1
fi
if [ -z $ES_PORT ]; then
    echo "ERROR: Environment variable ES_PORT for Elasticsearch port number is not set."
    exit 1
fi

# How many outputs?
if [ -n "${MUX_CLIENT_MODE:-}" ] ; then
    # A fluentd collector configured as a mux client has just one output: sending to a mux.
    NUM_OUTPUTS=1
    rm -f $CFG_DIR/openshift/filter-post-z-retag-*.conf
    if [ -n "$output_label" ]; then
        cp $CFG_DIR/{,openshift}/filter-post-z-mux-client.conf
    fi
    # Enable "output-es-ops-config.conf in output-operations.conf"
    # we need something there so output-operations.conf won't have an empty @copy without a <store> block
    # but it won't actually be used in this case - output-pre-mux-client.conf will match everything
    # before we get here
    cp $CFG_DIR/{openshift,dynamic}/output-es-ops-config.conf
else
    # check ES_HOST vs. OPS_HOST; ES_PORT vs. OPS_PORT
    if [ "$ES_HOST" = ${OPS_HOST:-""} -a $ES_PORT -eq ${OPS_PORT:-0} ]; then
        # There is one output Elasticsearch
        NUM_OUTPUTS=1
        # Disable "output-operations.conf"
        rm -f $CFG_DIR/openshift/output-operations.conf
        touch $CFG_DIR/openshift/output-operations.conf
        rm -f $CFG_DIR/openshift/filter-post-z-retag-*.conf $CFG_DIR/openshift/filter-post-mux-client.conf
        if [ -n "$output_label"  ]; then
            cp $CFG_DIR/{,openshift}/filter-post-z-retag-one.conf
        fi
    else
        NUM_OUTPUTS=2
        # Enable "output-es-ops-config.conf in output-operations.conf"
        cp $CFG_DIR/{openshift,dynamic}/output-es-ops-config.conf
        cp $CFG_DIR/{openshift,dynamic}/output-es-ops-retry.conf
        rm -f $CFG_DIR/openshift/filter-post-z-retag-*.conf $CFG_DIR/openshift/filter-post-mux-client.conf
        if [ -n "$output_label" ]; then
            cp $CFG_DIR/{,openshift}/filter-post-z-retag-two.conf
        fi
    fi
fi

# If FILE_BUFFER_PATH exists and it is not a directory, mkdir fails with the error.
FILE_BUFFER_PATH=/var/lib/fluentd
mkdir -p $FILE_BUFFER_PATH

# Get the available disk size.
DF_LIMIT=$(df -B1 $FILE_BUFFER_PATH --output=avail | tail -1)
DF_LIMIT=${DF_LIMIT:-0}
# Check how many mount points share the same filesystem (in case hostmount)
MCNT=$( mount | grep $( mount | grep "$FILE_BUFFER_PATH" | awk '{print $1}' ) | wc -l )
if [ $MCNT -gt 1 ]; then
    # Use 1/4 of the disk space for the file buffer
    # in case user specified FILE_BUFFER_LIMIT is too large.
    DF_LIMIT=$(expr $DF_LIMIT / 4) || :
fi
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

# If forward and secure-forward outputs are configured, add them to NUM_OUTPUTS.
forward_files=$( grep -l "@type .*forward" ${CFG_DIR}/*/* 2> /dev/null || : )
for afile in ${forward_files} ; do
    file=$( basename $afile )
    if [ "$file" != "${mux_client_filename:-}" ]; then
        grep "@type .*forward" $afile | while read -r line; do
            if [ $( expr "$line" : "^ *#" ) -eq 0 ]; then
                NUM_OUTPUTS=$( expr $NUM_OUTPUTS + 1 )
            fi
        done
    fi
done

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
elif [ -d /var/lib/docker/containers ] ; then
    # If oci-umount is fixed, we can remove this. 
    if [ -n "${VERBOSE:-}" ] ; then
        echo "umounts of dead containers will fail. Ignoring..."
        umount /var/lib/docker/containers/*/shm || :
    else
        umount /var/lib/docker/containers/*/shm > /dev/null 2>&1 || :
    fi
fi

if [[ "${USE_REMOTE_SYSLOG:-}" = "true" ]] ; then
    # The symlink is a workaround for https://github.com/openshift/origin-aggregated-logging/issues/604
    found=
    for file in /usr/share/gems/gems/fluent-plugin-remote-syslog-*/lib/fluentd/plugin/*.rb ; do
        bname=$(basename $file)
        if [ ! -e "/etc/fluent/plugin/$bname" -a -f "$file" ] ; then
            ln -s $file /etc/fluent/plugin/
            found=true
        fi
    done
    if [ -z "${found:-}" ] ; then
        # not found in rpm location - look in alternate location
        for file in /opt/app-root/src/gems/fluent-plugin-remote-syslog*/lib/fluentd/plugin/*.rb ; do
            bname=$(basename $file)
            if [ ! -e "/etc/fluent/plugin/$bname" -a -f "$file" ] ; then
                ln -s $file /etc/fluent/plugin/
            fi
        done
    fi
    if [[ $REMOTE_SYSLOG_HOST ]] ; then
        ruby generate_syslog_config.rb
    fi
fi

# Disable process_kubernetes_events if TRANSFORM_EVENTS is false or MUX client.
if [ "${TRANSFORM_EVENTS:-}" != true -o -n "${MUX_CLIENT_MODE:-}" ] ; then
    sed -i 's/\(.*@type viaq_data_model.*\)/\1\n  process_kubernetes_events false/' $CFG_DIR/openshift/filter-viaq-data-model.conf
fi

if [ "${AUDIT_CONTAINER_ENGINE:-}" = "true" ] ; then
    cp -f $CFG_DIR/input-pre-audit-log.conf $CFG_DIR/openshift
    cp -f $CFG_DIR/filter-pre-a-audit-exclude.conf $CFG_DIR/openshift
else
    touch $CFG_DIR/openshift/input-pre-audit-log.conf
    touch $CFG_DIR/openshift/filter-pre-a-audit-exclude.conf
fi

if [ "${ENABLE_UTF8_FILTER:-}" != true ] ; then
    rm -f $CFG_DIR/openshift/filter-pre-force-utf8.conf
    touch $CFG_DIR/openshift/filter-pre-force-utf8.conf
fi

# Include DEBUG log level messages when collecting from journald
# https://bugzilla.redhat.com/show_bug.cgi?id=1505602
if [ "${COLLECT_JOURNAL_DEBUG_LOGS:-true}" = true ] ; then
  rm -f $CFG_DIR/openshift/filter-exclude-journal-debug.conf
  touch $CFG_DIR/openshift/filter-exclude-journal-debug.conf
fi

if [ "${ENABLE_PROMETHEUS_ENDPOINT}" != "true" ] ; then
  echo "INFO: Disabling Prometheus endpoint"
  rm -f ${CFG_DIR}/openshift/input-pre-prometheus-metrics.conf
fi

# convert journal.pos file to new format
if [ -f /var/log/journal.pos -a ! -f /var/log/journal_pos.json ] ; then
    echo Converting old fluent-plugin-systemd pos file format to new format
    cursor=$( cat /var/log/journal.pos )
    echo '{"journal":"'"$cursor"'"}' > /var/log/journal_pos.json
    rm /var/log/journal.pos
fi

issue_deprecation_warnings

# this should be the last thing before launching fluentd so as not to use
# jemalloc with any other processes
if type -p jemalloc-config > /dev/null 2>&1 && [ "${USE_JEMALLOC:-true}" = true ] ; then
    export LD_PRELOAD=$( jemalloc-config --libdir )/libjemalloc.so.$( jemalloc-config --revision )
    export LD_BIND_NOW=1 # workaround for https://bugzilla.redhat.com/show_bug.cgi?id=1544815
fi
exec fluentd $fluentdargs

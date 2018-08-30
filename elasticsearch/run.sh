#!/bin/bash

set -euo pipefail

if [ ${DEBUG:-""} = "true" ]; then
    set -x
    LOGLEVEL=7
fi

source "logging"

info Begin Elasticsearch startup script

export KUBERNETES_AUTH_TRYKUBECONFIG=${KUBERNETES_AUTH_TRYKUBECONFIG:-"false"}

MEM_LIMIT_FILE=/etc/podinfo/mem_limit
CONTAINER_MEM_LIMIT=${INSTANCE_RAM:-}

mkdir -p /elasticsearch/$CLUSTER_NAME

BYTES_PER_MEG=$((1024*1024))
BYTES_PER_GIG=$((1024*${BYTES_PER_MEG}))

MAX_ES_MEMORY_BYTES=$((64*${BYTES_PER_GIG}))
MIN_ES_MEMORY_BYTES=$((256*${BYTES_PER_MEG}))

if [[ -e $MEM_LIMIT_FILE ]]; then
  limit=$(cat $MEM_LIMIT_FILE)
  limit=$((limit/$BYTES_PER_MEG))

  CONTAINER_MEM_LIMIT="${limit}M"
fi

# the amount of RAM allocated should be half of available instance RAM.
# ref. https://www.elastic.co/guide/en/elasticsearch/guide/current/heap-sizing.html#_give_half_your_memory_to_lucene
# parts inspired by https://github.com/fabric8io-images/run-java-sh/blob/master/fish-pepper/run-java-sh/fp-files/java-container-options
regex='^([[:digit:]]+)([GgMm])i?$'
if [[ "$CONTAINER_MEM_LIMIT" =~ $regex ]]; then
    num=${BASH_REMATCH[1]}
    unit=${BASH_REMATCH[2]}
    if [[ $unit =~ [Gg] ]]; then
        ((num = num * ${BYTES_PER_GIG})) # enables math to work out for odd Gi
    elif [[ $unit =~ [Mm] ]]; then
        ((num = num * ${BYTES_PER_MEG})) # enables math to work out for odd Gi
    fi

    #determine if req is less then max recommended by ES
    info "Comparing the specified RAM to the maximum recommended for Elasticsearch..."
    if [ ${MAX_ES_MEMORY_BYTES} -lt ${num} ]; then
        ((num = ${MAX_ES_MEMORY_BYTES}))
        warn "Downgrading the CONTAINER_MEM_LIMIT to $(($num / BYTES_PER_MEG))m because ${CONTAINER_MEM_LIMIT} will result in a larger heap then recommended."
    fi

    #determine max allowable memory
    info "Inspecting the maximum RAM available..."
    mem_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"
    if [ -r "${mem_file}" ]; then
        max_mem="$(cat ${mem_file})"
        if [ ${max_mem} -lt ${num} ]; then
            ((num = ${max_mem}))
            warn "Setting the maximum allowable RAM to $(($num / BYTES_PER_MEG))m which is the largest amount available"
        fi
    else
        error "Unable to determine the maximum allowable RAM for this host in order to configure Elasticsearch"
        exit 1
    fi

    if [[ $num -lt $MIN_ES_MEMORY_BYTES ]]; then
        error "A minimum of $(($MIN_ES_MEMORY_BYTES/$BYTES_PER_MEG))m is required but only $(($num/$BYTES_PER_MEG))m is available or was specified"
        exit 1
    fi
    num=$(($num/2/BYTES_PER_MEG))
    export ES_JAVA_OPTS="${ES_JAVA_OPTS:-} -Xms${num}m -Xmx${num}m"
    info "ES_JAVA_OPTS: '${ES_JAVA_OPTS}'"
else
    error "CONTAINER_MEM_LIMIT is invalid: $CONTAINER_MEM_LIMIT"
    exit 1
fi

cat <<CONF >> ${HOME}/sgconfig/sg_roles_mapping.yml
sg_role_prometheus:
  users:
    - "${PROMETHEUS_USER:-system:serviceaccount:prometheus:prometheus}"
CONF

build_jks_truststores
./init.sh &

# this is because the deployment mounts the configmap at /usr/share/java/elasticsearch/config
cp /usr/share/java/elasticsearch/config/* $ES_CONF

HEAP_DUMP_LOCATION="${HEAP_DUMP_LOCATION:-/elasticsearch/persistent/hdump.prof}"
info Setting heap dump location "$HEAP_DUMP_LOCATION"
export ES_JAVA_OPTS="${ES_JAVA_OPTS:-} -XX:HeapDumpPath=$HEAP_DUMP_LOCATION -Dsg.display_lic_none=false"
info "ES_JAVA_OPTS: '${ES_JAVA_OPTS}'"

exec ${ES_HOME}/bin/elasticsearch -E path.conf=$ES_CONF

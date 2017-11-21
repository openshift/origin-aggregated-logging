#!/bin/bash

set -euo pipefail

if [ ${DEBUG:-""} = "true" ]; then
    set -x
    LOGLEVEL=7
fi

source "logging"

info Begin Elasticsearch startup script

export KUBERNETES_AUTH_TRYKUBECONFIG=${KUBERNETES_AUTH_TRYKUBECONFIG:-"false"}
ES_REST_BASEURL=${ES_REST_BASEURL:-https://localhost:9200}
LOG_FILE=${LOG_FILE:-elasticsearch_connect_log.txt}
RETRY_COUNT=${RETRY_COUNT:-300}		# how many times
RETRY_INTERVAL=${RETRY_INTERVAL:-1}	# how often (in sec)

retry=$RETRY_COUNT
max_time=$(( RETRY_COUNT * RETRY_INTERVAL ))	# should be integer
timeouted=false

mkdir -p /elasticsearch/$CLUSTER_NAME
secret_dir=/etc/elasticsearch/secret

BYTES_PER_MEG=$((1024*1024))
BYTES_PER_GIG=$((1024*${BYTES_PER_MEG}))

MAX_ES_MEMORY_BYTES=$((64*${BYTES_PER_GIG}))
MIN_ES_MEMORY_BYTES=$((256*${BYTES_PER_MEG}))

# the amount of RAM allocated should be half of available instance RAM.
# ref. https://www.elastic.co/guide/en/elasticsearch/guide/current/heap-sizing.html#_give_half_your_memory_to_lucene
# parts inspired by https://github.com/fabric8io-images/run-java-sh/blob/master/fish-pepper/run-java-sh/fp-files/java-container-options
regex='^([[:digit:]]+)([GgMm])i?$'
if [[ "${INSTANCE_RAM:-}" =~ $regex ]]; then
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
        warn "Downgrading the INSTANCE_RAM to $(($num / BYTES_PER_MEG))m because ${INSTANCE_RAM} will result in a larger heap then recommended."
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

    # Set JVM HEAP size to half of available space
    num=$(($num/2/BYTES_PER_MEG))
    export ES_HEAP_SIZE="${num}m"
    info "ES_HEAP_SIZE: '${ES_HEAP_SIZE}'"
else
    error "INSTANCE_RAM env var is invalid: ${INSTANCE_RAM:-}"
    exit 1
fi

cat <<CONF >> ${HOME}/sgconfig/sg_roles_mapping.yml
sg_role_prometheus:
  users:
    - "${PROMETHEUS_USER:-system:serviceaccount:prometheus:prometheus}"
CONF

# Wait for Elasticsearch port to be opened. Fail on timeout or if response from Elasticsearch is unexpected.
wait_for_port_open() {
    rm -f $LOG_FILE
    # test for ES to be up first and that our SG index has been created
    info "Checking if Elasticsearch is ready on $ES_REST_BASEURL"
    while ! response_code=$(curl ${DEBUG:+-v} -s \
        --request HEAD --head \
        --cacert $secret_dir/admin-ca \
        --cert $secret_dir/admin-cert \
        --key  $secret_dir/admin-key \
        --max-time $max_time \
        -o $LOG_FILE -w '%{response_code}' \
        $ES_REST_BASEURL) || test $response_code != "200"
    do
        sleep $RETRY_INTERVAL
        (( retry -= 1 )) || :
        if (( retry == 0 )) ; then
            timeouted=true
            break
        fi
    done

    if [ $timeouted = true ] ; then
        error "Timed out waiting for Elasticsearch to be ready"
    else
        rm -f $LOG_FILE
        info Elasticsearch is ready and listening at $ES_REST_BASEURL
        return 0
    fi
    cat $LOG_FILE
    rm -f $LOG_FILE
    exit 1
}

verify_or_add_index_templates() {
    wait_for_port_open
    es_seed_acl
    # Uncomment this if you want to wait for cluster becoming more stable before index template being pushed in.
    # Give up on timeout and continue...
    # curl -v -s -X GET \
    #     --cacert $secret_dir/admin-ca \
    #     --cert $secret_dir/admin-cert \
    #     --key  $secret_dir/admin-key \
    #     "$ES_REST_BASEURL/_cluster/health?wait_for_status=yellow&timeout=${max_time}s"

    info Adding index templates
    shopt -s failglob
    for template_file in ${ES_HOME}/index_templates/*.json
    do
        template=`basename $template_file`
        # Check if index template already exists
        response_code=$(curl ${DEBUG:+-v} -s \
            --request HEAD --head --output /dev/null \
            --cacert $secret_dir/admin-ca \
            --cert $secret_dir/admin-cert \
            --key  $secret_dir/admin-key \
            -w '%{response_code}' \
            $ES_REST_BASEURL/_template/$template)
        if [ $response_code == "200" ]; then
            info "Index template '$template' already present in ES cluster"
        else
            info "Create index template '$template'"
            curl ${DEBUG:+-v} -s -X PUT \
                --cacert $secret_dir/admin-ca \
                --cert $secret_dir/admin-cert \
                --key  $secret_dir/admin-key \
                -d@$template_file \
                $ES_REST_BASEURL/_template/$template
        fi
    done
    shopt -u failglob
    info Finished adding index templates
}

verify_or_add_index_templates &

HEAP_DUMP_LOCATION="${HEAP_DUMP_LOCATION:-/elasticsearch/persistent/hdump.prof}"
info Setting heap dump location "$HEAP_DUMP_LOCATION"
export JAVA_OPTS="${JAVA_OPTS:-} -XX:HeapDumpPath=$HEAP_DUMP_LOCATION"

exec ${ES_HOME}/bin/elasticsearch --path.conf=$ES_CONF --security.manager.enabled false

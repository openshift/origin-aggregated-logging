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
    export ES_JAVA_OPTS="${ES_JAVA_OPTS:-} -Xms$(($num/2/BYTES_PER_MEG))m -Xmx$(($num/2/BYTES_PER_MEG))m"
    echo "ES_JAVA_OPTS: '${ES_JAVA_OPTS}'"
else
    error "INSTANCE_RAM env var is invalid: ${INSTANCE_RAM:-}"
    exit 1
fi

# Wait for Elasticsearch port to be opened. Fail on timeout or if response from Elasticsearch is unexpected.
wait_for_port_open() {
    rm -f $LOG_FILE
    # test for ES to be up first and that our SG index has been created
    echo -n "Checking if Elasticsearch is ready on $ES_REST_BASEURL "
    while ! response_code=$(curl ${DEBUG:+-v} -s --head \
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
}

verify_or_add_index_templates() {
    wait_for_port_open
    es_seed_acl
    # Give up on timeout and continue...
    # Uncomment this if you want to wait for cluster becoming more stable before index template being pushed in.
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
	info Adding template $template
        response_code=$(curl ${DEBUG:+-v} -s --head \
            --cacert $secret_dir/admin-ca \
            --cert $secret_dir/admin-cert \
            --key  $secret_dir/admin-key \
            -w '%{response_code}' \
            --max-time $max_time \
            $ES_REST_BASEURL/_template/$template)
        if [ $response_code == "200" ]; then
            info "Index template '$template' already present in ES cluster"
        else
            echo "Create index template '$template'"
            curl -v -s -X PUT \
                --cacert $secret_dir/admin-ca \
                --cert $secret_dir/admin-cert \
                --key  $secret_dir/admin-key \
                -d@$template_file \
                $ES_REST_BASEURL/_template/$template
        fi
    done
#    shopt -u failglob
    info Finished adding index templates
}

if [ $IS_MASTER == "false" ]; then
  verify_or_add_index_templates &
fi

cp /usr/share/java/elasticsearch/config/* /etc/elasticsearch/

HEAP_DUMP_LOCATION="${HEAP_DUMP_LOCATION:-/elasticsearch/persistent/hdump.prof}"
info Setting heap dump location "$HEAP_DUMP_LOCATION"
export JAVA_OPTS="${JAVA_OPTS:-} -XX:HeapDumpPath=$HEAP_DUMP_LOCATION"

exec ${ES_HOME}/bin/elasticsearch -Epath.conf=$ES_CONF

#!/bin/bash

set -euo pipefail

ES_REST_BASEURL=https://localhost:9200
LOG_FILE=elasticsearch_connect_log.txt
RETRY_COUNT=30		# how many times
RETRY_INTERVAL=1	# how often (in sec)

retry=${RETRY_COUNT}
max_time=$(( RETRY_COUNT * RETRY_INTERVAL ))	# should be integer
timeouted=false

mkdir -p /elasticsearch/$CLUSTER_NAME
secret_dir=/etc/elasticsearch/secret/
[ -f $secret_dir/searchguard-node-key ] && ln -s $secret_dir/searchguard-node-key /elasticsearch/$CLUSTER_NAME/searchguard_node_key.key
[ -f $secret_dir/searchguard.key ] && ln -s $secret_dir/searchguard.key /elasticsearch/$CLUSTER_NAME/searchguard_node_key.key
[ -f $secret_dir/keystore.password ] && export KEYSTORE_PASSWORD=$(cat $secret_dir/keystore.password)
[ -f $secret_dir/truststore.password ] && export TRUSTSTORE_PASSWORD=$(cat $secret_dir/truststore.password)

BYTES_PER_MEG=$((1024*1024))
BYTES_PER_GIG=$((1024*${BYTES_PER_MEG}))

MAX_ES_MEMORY_BYTES=$((64*${BYTES_PER_GIG}))
MIN_ES_MEMORY_BYTES=$((256*${BYTES_PER_MEG}))

# the amount of RAM allocated should be half of available instance RAM.
# ref. https://www.elastic.co/guide/en/elasticsearch/guide/current/heap-sizing.html#_give_half_your_memory_to_lucene
# parts inspired by https://github.com/fabric8io-images/run-java-sh/blob/master/fish-pepper/run-java-sh/fp-files/java-container-options
regex='^([[:digit:]]+)([GgMm])$'
if [[ "${INSTANCE_RAM:-}" =~ $regex ]]; then
	num=${BASH_REMATCH[1]}
	unit=${BASH_REMATCH[2]}
	if [[ $unit =~ [Gg] ]]; then
		((num = num * ${BYTES_PER_GIG})) # enables math to work out for odd Gi
	elif [[ $unit =~ [Mm] ]]; then
		((num = num * ${BYTES_PER_MEG})) # enables math to work out for odd Gi
	fi

    #determine if req is less then max recommended by ES
    echo "Comparing the specificed RAM to the maximum recommended for ElasticSearch..."
    if [ ${MAX_ES_MEMORY_BYTES} -lt ${num} ]; then
      ((num = ${MAX_ES_MEMORY_BYTES}))
      echo "Downgrading the INSTANCE_RAM to $(($num / BYTES_PER_MEG))m because ${INSTANCE_RAM} will result in a larger heap then recommended."
    fi

    #determine max allowable memory 
    echo "Inspecting the maximum RAM available..."
    mem_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"
    if [ -r "${mem_file}" ]; then
      max_mem="$(cat ${mem_file})"
      if [ ${max_mem} -lt ${num} ]; then
        ((num = ${max_mem}))
        echo "Setting the maximum allowable RAM to $(($num / BYTES_PER_MEG))m which is the largest amount available"
      fi
    else
        echo "Unable to determine the maximum allowable RAM for this host in order to configure ElasticSearch"
        exit 1
	fi

	if [[ $num -lt $MIN_ES_MEMORY_BYTES ]]; then
        echo "A minimum of $(($MIN_ES_MEMORY_BYTES/$BYTES_PER_MEG))m is required but only $(($num/$BYTES_PER_MEG))m is available or was specified"
		exit 1
	fi
	export ES_JAVA_OPTS="${ES_JAVA_OPTS:-} -Xms128M -Xmx$(($num/2/BYTES_PER_MEG))m"
    echo "ES_JAVA_OPTS: '${ES_JAVA_OPTS}'"
else
	echo "INSTANCE_RAM env var is invalid: ${INSTANCE_RAM:-}"
	exit 1
fi


# Wait for Elasticsearch port to be opened. Fail on timeout or if response from Elasticsearch is unexpected.
wait_for_port_open() {
	rm -f ${LOG_FILE}
	echo -n "Checking if Elasticsearch is ready on ${ES_REST_BASEURL} "
	while ! curl -s -k \
			--cert ${secret_dir}admin-cert \
			--key  ${secret_dir}admin-key \
			--max-time ${max_time} \
			-o ${LOG_FILE} \
			${ES_REST_BASEURL} && [ ${timeouted} == false ]
	do
		echo -n "."
		sleep ${RETRY_INTERVAL}
		(( retry -= 1 ))
		if (( retry == 0 )) ; then
			timeouted=true
		fi
	done

	# Test for response code 200 in Elasticsearch output. This can be sensitive to Elasticsearch version.
	if [ -f ${LOG_FILE} ] && grep -q "200" ${LOG_FILE} ; then
		echo "- connection successful"
	else
		if [ ${timeouted} == true ] ; then
			echo -n "[timeout] "
		fi
		echo "failed"
		cat ${LOG_FILE}
		exit 1
	fi
}

verify_or_add_index_templates() {
	wait_for_port_open
	# Try to wait for cluster become more stable before index template being pushed in.
	# Give up on timeout and continue...
	curl -v -s -k -X GET \
		--cert ${secret_dir}admin-cert \
		--key  ${secret_dir}admin-key \
		"${ES_REST_BASEURL}/_cluster/health?wait_for_status=yellow&timeout=${max_time}s"

	shopt -s failglob
	for template_file in /usr/share/elasticsearch/index_templates/*.json
	do
		template=`basename $template_file`
		# Check if index template already exists
		response_code=$(curl -s -k -X HEAD \
			--cert ${secret_dir}admin-cert \
			--key  ${secret_dir}admin-key \
			-w '%{response_code}' \
			${ES_REST_BASEURL}/_template/$template)
		if [ $response_code == "200" ]; then
			echo "Index template '$template' already present in ES cluster"
		else
			echo "Create index template '$template'"
			curl -v -s -k -X PUT \
				--cert ${secret_dir}admin-cert \
				--key  ${secret_dir}admin-key \
				-d@$template_file \
				${ES_REST_BASEURL}/_template/$template
		fi
	done
	shopt -u failglob
}

verify_or_add_index_templates &

exec /usr/share/elasticsearch/bin/elasticsearch

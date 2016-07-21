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

# the amount of RAM allocated should be half of available instance RAM.
# ref. https://www.elastic.co/guide/en/elasticsearch/guide/current/heap-sizing.html#_give_half_your_memory_to_lucene
regex='^([[:digit:]]+)([GgMm])$'
if [[ "${INSTANCE_RAM:-}" =~ $regex ]]; then
	num=${BASH_REMATCH[1]}
	unit=${BASH_REMATCH[2]}
	if [[ $unit =~ [Gg] ]]; then
		((num = num * 1024)) # enables math to work out for odd Gi
	fi
	if [[ $num -lt 256 ]]; then
		echo "INSTANCE_RAM set to ${INSTANCE_RAM} but must be at least 256M"
		exit 1
	fi
	export ES_JAVA_OPTS="${ES_JAVA_OPTS:-} -Xms128M -Xmx$(($num/2))m"
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

verify_or_add_index_template() {
	wait_for_port_open
	# Try to wait for cluster become more stable before index template being pushed in.
	# Give up on timeout and continue...
	curl -v -s -k -X GET \
		--cert ${secret_dir}admin-cert \
		--key  ${secret_dir}admin-key \
		"${ES_REST_BASEURL}/_cluster/health?wait_for_status=yellow&timeout=${max_time}s"
	# Check if index template already exists
	response_code=$(curl -s -k -X HEAD \
		--cert ${secret_dir}admin-cert \
		--key  ${secret_dir}admin-key \
		-w '%{response_code}' \
		${ES_REST_BASEURL}/_template/viaq)
	if [ $response_code == "200" ]; then
		echo "Index template already present in ES cluster"
	else
		echo "Create index template"
		curl -v -s -k -X PUT \
			--cert ${secret_dir}admin-cert \
			--key  ${secret_dir}admin-key \
			-d@/usr/share/elasticsearch/config/com.redhat.viaq.template.json \
			${ES_REST_BASEURL}/_template/viaq
	fi
}

verify_or_add_index_template &

exec /usr/share/elasticsearch/bin/elasticsearch

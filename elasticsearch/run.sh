#!/bin/bash

set -euo pipefail

# convert our secrets to JKS if necessary

function importPKCS() {
  dir=${SCRATCH_DIR:-_output}
  NODE_NAME=$1
	FILE_NAME=${2:-$dir/$NODE_NAME.pkcs12}
	KEY_NAME=${3:-$dir/keystore.jks}
  ks_pass=${KS_PASS:-kspass}
  ts_pass=${TS_PASS:-tspass}
  rm -rf $NODE_NAME

  keytool \
    -importkeystore \
    -srckeystore $FILE_NAME \
    -srcstoretype PKCS12 \
    -srcstorepass pass \
    -deststorepass $ks_pass \
    -destkeypass $ks_pass \
    -destkeystore $KEY_NAME \
    -alias 1 \
    -destalias $NODE_NAME

  echo "Import back to keystore (including CA chain)"

  keytool  \
    -import \
    -file $dir/admin-ca  \
    -keystore $KEY_NAME  \
    -storepass $ks_pass  \
    -noprompt -alias sig-ca

  echo All done for $NODE_NAME
}

function createTruststore() {
	dir=${SCRATCH_DIR:-_output}
	FILE_NAME=${1:-$dir/truststore.jks}

  echo "Import CA to truststore for validating client certs"

  keytool  \
    -import \
    -file $dir/admin-ca  \
    -keystore $FILE_NAME  \
    -storepass $ts_pass  \
    -noprompt -alias sig-ca
}

generated_dir="/elasticsearch/generated"
secret_dir="/etc/elasticsearch/secret"
SCRATCH_DIR=$secret_dir

[ ! -d $generated_dir ] && mkdir -p $generated_dir
# convert our secrets to JKS if necessary
[ ! -f $secret_dir/admin.jks ] && importPKCS "system.admin" "$secret_dir/admin" "$generated_dir/admin.jks"
[ ! -f $secret_dir/searchguard.key ] && importPKCS "elasticsearch" "$secret_dir/searchguard" "$generated_dir/searchguard.key"
[ ! -f $secret_dir/key ] && importPKCS "logging-es" "$secret_dir/elasticsearch" "$generated_dir/key"
[ ! -f $secret_dir/truststore ] && createTruststore "$generated_dir/truststore"
[ ! -f $secret_dir/searchguard.truststore ] && cp $generated_dir/truststore $generated_dir/searchguard.truststore

export KUBERNETES_AUTH_TRYKUBECONFIG="false"
ES_REST_BASEURL=https://localhost:9200
LOG_FILE=elasticsearch_connect_log.txt
RETRY_COUNT=300		# how many times
RETRY_INTERVAL=1	# how often (in sec)

retry=$RETRY_COUNT
max_time=$(( RETRY_COUNT * RETRY_INTERVAL ))	# should be integer
timeouted=false

mkdir -p /elasticsearch/$CLUSTER_NAME

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
	rm -f $LOG_FILE
    # test for ES to be up first and that our SG index has been created
	echo -n "Checking if Elasticsearch is ready on $ES_REST_BASEURL "
	while ! response_code=$(curl -s \
			--cacert $secret_dir/admin-ca \
			--cert $secret_dir/admin-cert \
			--key  $secret_dir/admin-key \
			--max-time $max_time \
			-o $LOG_FILE -w '%{response_code}' \
			"$ES_REST_BASEURL/.searchguard.${HOSTNAME}") || test $response_code != "200"
	do
		echo -n "."
		sleep $RETRY_INTERVAL
		(( retry -= 1 ))
		if (( retry == 0 )) ; then
			timeouted=true
            break
		fi
	done

	if [ $timeouted = true ] ; then
		echo -n "[timeout] "
    else
        rm -f $LOG_FILE
        return 0
	fi
	echo "failed"
	cat $LOG_FILE
    rm -f $LOG_FILE
	exit 1
}

verify_or_add_index_templates() {
	wait_for_port_open
	# Uncomment this if you want to wait for cluster becoming more stable before index template being pushed in.
	# Give up on timeout and continue...
	# curl -v -s -X GET \
	#	--cacert $secret_dir/admin-ca \
	#	--cert $secret_dir/admin-cert \
	#	--key  $secret_dir/admin-key \
	#	"$ES_REST_BASEURL/_cluster/health?wait_for_status=yellow&timeout=${max_time}s"

	shopt -s failglob
	for template_file in /usr/share/elasticsearch/index_templates/*.json
	do
		template=`basename $template_file`
		# Check if index template already exists
		response_code=$(curl -s -X HEAD \
			--cacert $secret_dir/admin-ca \
			--cert $secret_dir/admin-cert \
			--key  $secret_dir/admin-key \
			-w '%{response_code}' \
			$ES_REST_BASEURL/_template/$template)
		if [ $response_code == "200" ]; then
			echo "Index template '$template' already present in ES cluster"
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
	shopt -u failglob
}

verify_or_add_index_templates &

exec /usr/share/elasticsearch/bin/elasticsearch --path.conf=$ES_CONF --security.manager.enabled false

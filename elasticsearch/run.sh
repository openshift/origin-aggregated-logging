#!/bin/bash

set -euo pipefail

secret_dir=/etc/elasticsearch/secret
config_dir=/etc/elasticsearch/config

# ES seems to be picky about its config/ dir and permissions within it -- ln -s would yield incorrect permissions...
[ -f $secret_dir/searchguard.key ] && cp $secret_dir/searchguard.key $ES_CONF/$CLUSTER_NAME.key
[ -f $secret_dir/searchguard.truststore ] && cp $secret_dir/searchguard.truststore $ES_CONF/$CLUSTER_NAME.truststore
[ -f $config_dir/elasticsearch.yml ] && cp $config_dir/elasticsearch.yml $ES_CONF/elasticsearch.yml
[ -f $config_dir/logging.yml ] && cp $config_dir/logging.yml $ES_CONF/logging.yml

[ -f $secret_dir/key ] && cp $secret_dir/key $ES_CONF/key
[ -f $secret_dir/truststore ] && cp $secret_dir/truststore $ES_CONF/truststore

[ -f $secret_dir/admin-cert ] && cp $secret_dir/admin-cert $ES_CONF/admin-cert
[ -f $secret_dir/admin-key ] && cp $secret_dir/admin-key $ES_CONF/admin-key
[ -f $secret_dir/admin-ca ] && cp $secret_dir/admin-ca $ES_CONF/admin-ca

export KUBERNETES_AUTH_TRYKUBECONFIG="false"

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

ln -s /usr/share/elasticsearch/config/${CLUSTER_NAME}.truststore /usr/share/elasticsearch/config/${CLUSTER_NAME}.truststore.jks
cp /etc/elasticsearch/secret/admin-jks /usr/share/elasticsearch/config/admin.jks

#TODO: update the whitelist to work instead of completely disabling security manager
exec /usr/share/elasticsearch/bin/elasticsearch --path.conf=$ES_CONF --security.manager.enabled false

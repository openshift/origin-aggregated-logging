#!/bin/bash

set -euo pipefail

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

exec /usr/share/elasticsearch/bin/elasticsearch

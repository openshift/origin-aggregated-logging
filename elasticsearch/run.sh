#!/bin/bash

mkdir -p /elasticsearch/$CLUSTER_NAME
ln -s /etc/elasticsearch/keys/searchguard.key /elasticsearch/$CLUSTER_NAME/searchguard_node_key.key

# the amount of RAM allocated should be half of available instance RAM.
# ref. https://www.elastic.co/guide/en/elasticsearch/guide/current/heap-sizing.html#_give_half_your_memory_to_lucene
regex='^([[:digit:]]+)([GgMm])$'
if [[ "${INSTANCE_RAM}" =~ $regex ]]; then
	ES_JAVA_OPTS="${ES_JAVA_OPTS} -Xms256M -Xmx$((${BASH_REMATCH[1]}/2))${BASH_REMATCH[2]}"
else
	echo "INSTANCE_RAM env var is invalid: ${INSTANCE_RAM}"
	exit 1
fi


/usr/share/elasticsearch/bin/elasticsearch

#! /bin/bash

mkdir -p /elasticsearch/$CLUSTER_NAME
ln -s /etc/elasticsearch/keys/searchguard.key /elasticsearch/$CLUSTER_NAME/searchguard_node_key.key

# do an initial run to initialize the SearchGuard ACL
sed --in-place=.bak '
	s/searchguard.ssl.transport.http.enabled: true/searchguard.ssl.transport.http.enabled: false/
	s/allow_all_from_loopback: false/allow_all_from_loopback: true/
        s/minimum_master_nodes: .*/minimum_master_nodes: 1/
	s/recover_after_nodes: .*/recover_after_nodes: 1/
	s/expected_nodes: .*/expected_nodes: 1/
	$a\
network.host: 127.0.0.1
	' $ES_CONF

nohup /usr/share/elasticsearch/bin/elasticsearch -Des.pidfile=./elasticsearch.pid &
until $(curl -s -f -o /dev/null --connect-timeout 1 -m 1 --head http://localhost:9200); do
    sleep 0.1;
done

# check to see if ES has started up yet
until $(curl -s -f -o /dev/null --connect-timeout 1 -m 1 --head http://localhost:9200); do
  sleep 0.1;
done

if [ -z $(curl -s -f 'http://localhost:9200/searchguard/ac/ac') ]; then
  curl -q -XPUT 'http://localhost:9200/searchguard/ac/ac?pretty' -d '
  {"acl": [
      {
        "__Comment__": "Default is to deny all access",
        "filters_bypass": [],
        "filters_execute": []
      },
      {
        "__Comment__": "This is so that fluentd can only write",
        "users": ["system.logging.fluentd"],
        "filters_bypass": [],
        "filters_execute": ["actionrequestfilter.fluentd"]
      },
      {
        "__Comment__": "This is so that Kibana can do anything in the .kibana index",
        "users": ["system.logging.kibana"],
        "indices": [".kibana.*"],
        "filters_bypass": ["*"],
        "filters_execute": []
      },
      {
        "__Comment__": "This is so that Kibana can only read in all indices",
        "users": ["system.logging.kibana"],
        "filters_bypass": [],
        "filters_execute": ["actionrequestfilter.kibana"]
      }
  ]}'

  # check to make sure the ACL has been persisted
  until $(curl -s -f -o /dev/null --connect-timeout 1 -m 1 http://localhost:9200/searchguard/ac/ac); do
    sleep 0.1;
  done
fi

kill `cat ./elasticsearch.pid`
# put the settings back the way they were
mv $ES_CONF{.bak,}

# now run the real thing.

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

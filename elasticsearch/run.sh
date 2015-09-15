#! /bin/bash

mkdir -p /elasticsearch/$CLUSTER_NAME
ln -s /etc/elasticsearch/keys/searchguard.key /elasticsearch/$CLUSTER_NAME/searchguard_node_key.key

sed --in-place=.bak 's/searchguard.ssl.transport.http.enabled: true/searchguard.ssl.transport.http.enabled: false/' /usr/share/elasticsearch/config/elasticsearch.yml
sed -i 's/allow_all_from_loopback: false/allow_all_from_loopback: true/' /usr/share/elasticsearch/config/elasticsearch.yml
echo "" >> /usr/share/elasticsearch/config/elasticsearch.yml
echo "network.host: 127.0.0.1" >> /usr/share/elasticsearch/config/elasticsearch.yml

nohup /usr/share/elasticsearch/bin/elasticsearch -Des.pidfile=./elasticsearch.pid &

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
        "users": ["fluentd"],
        "filters_bypass": [],
        "filters_execute": ["actionrequestfilter.fluentd"]
      },
      {
        "__Comment__": "This is so that Kibana can do anything in the .kibana index",
        "users": ["kibana"],
        "indices": [".kibana"],
        "filters_bypass": ["*"],
        "filters_execute": []
      },
      {
        "__Comment__": "This is so that Kibana can only read in all indices",
        "users": ["kibana"],
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
mv /usr/share/elasticsearch/config/elasticsearch.yml.bak /usr/share/elasticsearch/config/elasticsearch.yml
/usr/share/elasticsearch/bin/elasticsearch

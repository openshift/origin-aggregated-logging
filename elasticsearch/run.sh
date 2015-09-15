#! /bin/bash

sed --in-place=.bak 's/searchguard.ssl.transport.http.enabled: true/searchguard.ssl.transport.http.enabled: false/' /usr/share/elasticsearch/config/elasticsearch.yml
sed -i 's/searchguard.allow_all_from_loopback: false/searchguard.allow_all_from_loopback: true/' /usr/share/elasticsearch/config/elasticsearch.yml
echo "network.host: 127.0.0.1" >> /usr/share/elasticsearch/config/elasticsearch.yml

nohup /usr/share/elasticsearch/bin/elasticsearch -Des.pidfile=./elasticsearch.pid &

sleep 20; curl -q -XPUT 'http://localhost:9200/searchguard/ac/ac?pretty' -d '
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

# doesn't work currently
#sleep 20; curl -q -XPUT 'http://localhost:9200/operations-2015.09.01/_mapping/kibana' -d '
# {"kibana": {
#    "transform": {
#      "script" : "ctx._source['message'] = ctx._source['msg']",
#      "lang": "groovy"
#    }
#  }
#}'

sleep 20; kill `cat ./elasticsearch.pid`

mv /usr/share/elasticsearch/config/elasticsearch.yml.bak /usr/share/elasticsearch/config/elasticsearch.yml

/usr/share/elasticsearch/bin/elasticsearch

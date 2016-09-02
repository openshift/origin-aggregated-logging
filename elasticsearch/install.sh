#!/bin/bash

set -ex

mkdir -p ${HOME}
ln -s /usr/share/elasticsearch /usr/share/java/elasticsearch

/usr/share/elasticsearch/bin/plugin install -b com.floragunn/search-guard-ssl/2.3.3.13
#/usr/share/elasticsearch/bin/plugin install -b com.floragunn/search-guard-2/2.3.3.3
/usr/share/elasticsearch/bin/plugin install -b file://${HOME}/search-guard-2-2.3.3.6.zip
/usr/share/elasticsearch/bin/plugin install io.fabric8/elasticsearch-cloud-kubernetes/2.3.3

#/usr/share/elasticsearch/bin/plugin install io.fabric8.elasticsearch/openshift-elasticsearch-plugin/2.3.3.1
/usr/share/elasticsearch/bin/plugin install file://${HOME}/openshift-elasticsearch-plugin-2.3.3.2.zip

mkdir /elasticsearch
mkdir -p $ES_CONF
chmod -R og+w $ES_CONF
chmod -R og+w /usr/share/java/elasticsearch ${HOME} /elasticsearch
chmod -R o+rx /etc/elasticsearch

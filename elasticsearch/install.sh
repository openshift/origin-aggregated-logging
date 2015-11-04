#!/bin/bash 

set -ex

rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
yum install -y --setopt=tsflags=nodocs \
  java-1.8.0-openjdk \
  elasticsearch
yum clean all

# need these so elasticsearch doesn't reject its config while installing plugins
export SERVICE_DNS=placeholder
export CLUSTER_NAME=placeholder

mkdir -p ${HOME}
ln -s /usr/share/elasticsearch /usr/share/java/elasticsearch
/usr/share/elasticsearch/bin/plugin -i com.floragunn/search-guard/0.5
/usr/share/elasticsearch/bin/plugin -i io.fabric8.elasticsearch/openshift-elasticsearch-plugin/0.7
/usr/share/elasticsearch/bin/plugin -i io.fabric8/elasticsearch-cloud-kubernetes/1.3.0
mkdir /elasticsearch
chmod -R og+w /usr/share/java/elasticsearch ${HOME} /elasticsearch

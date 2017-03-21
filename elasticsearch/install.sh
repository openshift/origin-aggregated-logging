#!/bin/bash

set -ex

mkdir -p ${HOME}
ln -s /usr/share/elasticsearch /usr/share/java/elasticsearch

/usr/share/elasticsearch/bin/plugin install -b com.floragunn/search-guard-ssl/${SG_SSL_VER}
/usr/share/elasticsearch/bin/plugin install -b com.floragunn/search-guard-2/${SG_VER}
/usr/share/elasticsearch/bin/plugin install io.fabric8/elasticsearch-cloud-kubernetes/${ES_CLOUD_K8S_VER}
/usr/share/elasticsearch/bin/plugin install io.fabric8.elasticsearch/openshift-elasticsearch-plugin/${OSE_ES_VER}


mkdir /elasticsearch
mkdir -p $ES_CONF
chmod -R og+w $ES_CONF
chmod -R og+w /usr/share/java/elasticsearch ${HOME} /elasticsearch
chmod -R o+rx /etc/elasticsearch
chmod +x /usr/share/elasticsearch/plugins/search-guard-2/tools/sgadmin.sh

PASSWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
cat > ${HOME}/sgconfig/sg_internal_users.yml << CONF
---
  $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1):
    hash: $PASSWD
CONF


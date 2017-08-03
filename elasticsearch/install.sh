#!/bin/bash

set -ex
set -o nounset

yum -y install https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VER}.rpm

source ${HOME}/prep-install.${RELEASE_STREAM}

echo "ES plugins: ${es_plugins[@]}"
for es_plugin in ${es_plugins[@]}
do
  ${ES_HOME}/bin/elasticsearch-plugin install -b $es_plugin
done


#fix location from config
ln -s ${ES_HOME}/index_templates /usr/share/elasticsearch/index_templates 
ln -s ${ES_HOME}/index_patterns /usr/share/elasticsearch/index_patterns 
ln -s ${ES_HOME}/kibana_ui_objects /usr/share/elasticsearch/kibana_ui_objects 

mkdir /elasticsearch
mkdir -p $ES_CONF
chmod -R og+w $ES_CONF ${ES_HOME} ${HOME} /elasticsearch
chmod -R o+rx /etc/elasticsearch
chmod +x ${ES_HOME}/plugins/search-guard-5/tools/sgadmin.sh

# document needed by sg plugin to properly initialize
passwd=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
cat > ${HOME}/sgconfig/sg_internal_users.yml << CONF
---
  $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1):
    hash: $passwd
CONF
unset passwd

#!/bin/bash

set -ex
set -o nounset

source ${HOME}/prep-install.${RELEASE_STREAM}

echo "ES plugins: ${es_plugins[@]}"
for es_plugin in ${es_plugins[@]}
do
  if [ -x ${ES_HOME}/bin/elasticsearch-plugin ] ; then
    plugincmd=${ES_HOME}/bin/elasticsearch-plugin
  else
    plugincmd=${ES_HOME}/bin/plugin
  fi
  $plugincmd install -b $es_plugin
done

#fix location from config
if [[ "${ES_HOME}" != "/usr/share/elasticsearch" ]]; then
  ln -s ${ES_HOME}/index_templates /usr/share/elasticsearch/index_templates
  ln -s ${ES_HOME}/index_patterns /usr/share/elasticsearch/index_patterns
  ln -s ${ES_HOME}/kibana_ui_objects /usr/share/elasticsearch/kibana_ui_objects
fi

if [ ! -d /elasticsearch ] ; then
  mkdir /elasticsearch
fi
if [ ! -d $ES_CONF ] ; then
  mkdir -p $ES_CONF
fi
chmod -R og+w $ES_CONF ${ES_HOME} ${HOME} /elasticsearch
chmod -R o+rx /etc/elasticsearch
chmod +x ${ES_HOME}/plugins/openshift-elasticsearch/sgadmin.sh

# document needed by sg plugin to properly initialize
passwd=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
cat > ${HOME}/sgconfig/sg_internal_users.yml << CONF
---
  $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1):
    hash: $passwd
CONF
unset passwd

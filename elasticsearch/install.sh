#!/bin/bash

set -euxo pipefail

ln -s /usr/local/bin/logging ${HOME}/logging

source ${HOME}/prep-install.${RELEASE_STREAM}

echo "removing module: ingest-geoip"
rm -rf ${ES_HOME}/modules/ingest-geoip

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
if [ -f ${ES_HOME}/plugins/openshift-elasticsearch/sgadmin.sh ] ; then
  chmod +x ${ES_HOME}/plugins/openshift-elasticsearch/sgadmin.sh
elif [ -f ${ES_HOME}/plugins/opendistro_security/tools/securityadmin.sh ]; then
  chmod +x ${ES_HOME}/plugins/opendistro_security/tools/securityadmin.sh
fi

# document needed by sg plugin to properly initialize
set +o pipefail
passwd=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)

cat > ${HOME}/sgconfig/internal_users.yml << CONF
---
  $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1):
    hash: $passwd
CONF
set -o pipefail
unset passwd
rm -rf /tmp/lib
# init scripts need these permissions/ownership because they write
# these files/dirs in place
chmod -R u+w,g+w ${HOME}/sgconfig ${ES_HOME}/index_templates

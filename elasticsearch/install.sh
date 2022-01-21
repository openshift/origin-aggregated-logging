#!/bin/bash

set -ex
set -o nounset

export ES_VER_REDHAT=${ES_VER_REDHAT}
source ${HOME}/prep-install.${RELEASE_STREAM}

pushd /var/tmp
    ES_ARCHIVE_URL=${ES_ARCHIVE_URL:-${MAVEN_REPO_URL}/org/elasticsearch/distribution/zip/elasticsearch/${ES_VER_REDHAT}/elasticsearch-${ES_VER_REDHAT}.zip}
    curl -L -v -s -o es.zip ${ES_ARCHIVE_URL}
    unzip es.zip
    pushd elasticsearch-${ES_VER}
      mkdir -p ${ES_HOME}/bin
      install -p -m 755 bin/elasticsearch ${ES_HOME}/bin
      install -p -m 644 bin/elasticsearch.in.sh ${ES_HOME}/bin
      install -p -m 755 bin/elasticsearch-plugin ${ES_HOME}/bin/plugin
      install -p -m 755 bin/elasticsearch-keystore ${ES_HOME}/bin/keystore
      mkdir -p ${ES_HOME}/plugins
      mkdir -p ${ES_HOME}/lib
      install -p -m 644 lib/*.jar ${ES_HOME}/lib
      cp -r modules ${ES_HOME}
      mkdir -p ${ES_CONF}/scripts
      install -m 644 config/* ${ES_CONF}
      sed -i -e 's/^-Xms/#-Xms/' -e 's/^-Xmx/#-Xmx/' ${ES_CONF}/jvm.options
      cat /etc/elasticsearch/extra-jvm.options >> ${ES_CONF}/jvm.options
      groupadd -r elasticsearch -g 1000
      useradd -r -g elasticsearch -d ${ES_HOME} -u 1000 \
              -s /sbin/nologin -c "You know, for search" elasticsearch
      mkdir -p ${ES_HOME}/data
      chown elasticsearch:elasticsearch ${ES_HOME}/data
      chmod 0777 ${ES_HOME}/data
      mkdir -p ${ES_HOME}/logs
      chown elasticsearch:elasticsearch ${ES_HOME}/logs
      chmod u+rwx,g+rwx ${ES_HOME}/logs
      mkdir -p /var/run/elasticsearch
      chmod u+rwx,g+rwx /var/run/elasticsearch
      mkdir /elasticsearch && chmod a+rwx /elasticsearch
  popd
popd

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

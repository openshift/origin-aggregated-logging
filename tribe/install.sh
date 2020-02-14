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

if [ ! -d /elasticsearch ] ; then
  mkdir /elasticsearch
fi
if [ ! -d $ES_CONF ] ; then
  mkdir -p $ES_CONF
fi
chmod -R og+w $ES_CONF ${ES_HOME} ${HOME} /elasticsearch
chmod -R o+rx /etc/elasticsearch

CONF
unset passwd

#!/bin/sh
set -euo pipefail

sed -i "s/es_host/$ES_HOST/" ${KIBANA_HOME}/config/kibana.yml
sed -i "s/es_port/$ES_PORT/" ${KIBANA_HOME}/config/kibana.yml

if [ -f "/etc/openshift/kibana/styles/overrides.css" ]; then
  cp -f /etc/openshift/kibana/styles/overrides.css ${KIBANA_HOME}/installedPlugins/origin-kibana/public/styles
  rm -rf ${KIBANA_HOME}/optimize/bundles/**
fi

if [ -d "/etc/openshift/kibana/images" ]; then
  cp -f /etc/openshift/kibana/images/* ${KIBANA_HOME}/installedPlugins/origin-kibana/public/images
fi

exec ${KIBANA_HOME}/bin/kibana

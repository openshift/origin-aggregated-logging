#!/bin/bash

set -ex
set -o nounset
set -o pipefail

mkdir -p ${HOME}
cd ${HOME}/
yum -y install https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VER}-x86_64.rpm

chmod -R og+w "${KIBANA_CONF_DIR}"
chmod -R 755 ${KIBANA_HOME}/installedPlugins/origin-kibana

source "${HOME}/prep-install.${RELEASE_STREAM}"

# Kibana starts up slowly because it tries to optimize and cache bundles
# so we start it up as part of install and then stop it
#mv "${KIBANA_CONF_DIR}/kibana.yml" "${KIBANA_CONF_DIR}/hidden_kibana.yml"
#touch "${KIBANA_CONF_DIR}/kibana.yml"

#touch "${KIBANA_HOME}/kibana.out"
#"${NODE_BIN}" "${KIBANA_HOME}/src/cli" > "${KIBANA_HOME}/kibana.out" &
#pid=$!

#until [ ! -z "${pid}" ] && [ -n "$(grep 'Optimization of bundles for kibana and statusPage complete' ${KIBANA_HOME}/kibana.out)" ]; do
#  sleep 1
#done

#if [ ! -z "${pid}" ] ; then
#  kill $pid
#fi

#rm "${KIBANA_HOME}/kibana.out"
#rm "${KIBANA_CONF_DIR}/kibana.yml"
#mv "${KIBANA_CONF_DIR}/hidden_kibana.yml" "${KIBANA_CONF_DIR}/kibana.yml"
chmod -R og+w "${HOME}"
chmod -R og+rw "${KIBANA_HOME}"


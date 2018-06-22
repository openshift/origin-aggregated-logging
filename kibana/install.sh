#!/bin/bash

set -ex
set -o nounset
set -o pipefail

source "${HOME}/prep-install.${RELEASE_STREAM}"

ORIGIN_KIBANA_PLUGIN=$(ls -t1 ${HOME}/origin-kibana-v${KIBANA_VER}*.zip | head -1)
${KIBANA_HOME}/bin/kibana-plugin install file://${ORIGIN_KIBANA_PLUGIN}

chmod -R og+w "${HOME}"
chmod -R og+rw "${KIBANA_HOME}"
mkdir -m og+w -p /var/lib/kibana
chmod -R og+w "${KIBANA_CONF_DIR}"

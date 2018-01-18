#!/bin/bash
#
# Copyright 2017 Red Hat, Inc. and/or its affiliates
# and other contributors as indicated by the @author tags.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

source "utils"

if [ -n "${DEBUG:-}" ] ; then
    set -x
    echo ">>>>> ENVIRONMENT VARS <<<<<<"
    env | sort
    echo ">>>>>>>>> END <<<<<<<<<<<<<<<"
    echo "logging.verbose: true" >> "${KIBANA_CONF_DIR}/kibana.yml"
fi

set -euo pipefail

# override styles for branding
if [ -f "/etc/openshift/kibana/styles/overrides.css" ]; then
  cp -f /etc/openshift/kibana/styles/overrides.css "${KIBANA_HOME}/installedPlugins/origin-kibana/public/styles"
  rm -rf "${KIBANA_HOME}/optimize/bundles/**"
fi

# override images for branding
if [ -d "/etc/openshift/kibana/images" ]; then
  cp -f /etc/openshift/kibana/images/* "${KIBANA_HOME}/installedPlugins/origin-kibana/public/images"
fi

if [ -n "${KIBANA_DEFAULTAPPID:-}" ] ; then
    echo Setting the kibana.defaultAppId to "${KIBANA_DEFAULTAPPID}"
    sed -i "s/^.*kibana\.defaultAppId.*/kibana\.defaultAppId: ${KIBANA_DEFAULTAPPID}/" "${KIBANA_CONF_DIR}/kibana.yml"
fi

#set the max memory
BYTES_PER_MEG=$((1024*1024))
BYTES_PER_GIG=$((1024*BYTES_PER_MEG))

DEFAULT_MIN=$((128 * BYTES_PER_MEG)) #This is a guess
regex='^([[:digit:]]+)([GgMm])?i?$'

if [[ "${KIBANA_MEMORY_LIMIT:-736M}" =~ $regex ]]; then
    num=${BASH_REMATCH[1]}
    unit=${BASH_REMATCH[2]}

    #set max_old_space_size to half of memory limit to allow some heap for other V8 spaces
    num=$((num/2))

    if [[ $unit =~ [Gg] ]]; then
        ((num = num * BYTES_PER_GIG)) # enables math to work out for odd Gi
    elif [[ $unit =~ [Mm] ]]; then
        ((num = num * BYTES_PER_MEG)) # enables math to work out for odd Gi
    #else assume bytes
    fi

    if [[ $num -lt $DEFAULT_MIN ]] ; then
        echo "$num is less then the default $((DEFAULT_MIN / BYTES_PER_MEG))m.  Setting to default."
        ((num = DEFAULT_MIN))
    fi

    export NODE_OPTIONS="--max_old_space_size=$((num / BYTES_PER_MEG))"

else
    echo "Unable to process the KIBANA_MEMORY_LIMIT: '${KIBANA_MEMORY_LIMIT}'.  It must be in the format of: /${regex}/"
    exit 1
fi

if [ -z "${ELASTICSEARCH_URL:-}" ] ; then
  ELASTICSEARCH_URL="https://${ES_HOST:-localhost}:${ES_PORT:-9200}"
fi
update_config_from_env_vars ${KIBANA_CONF_DIR}

echo "Using NODE_OPTIONS: '${NODE_OPTIONS:-}' Memory setting is in MB"

set -a && source /etc/sysconfig/kibana && "${NODE_BIN}" "${KIBANA_HOME}/src/cli"

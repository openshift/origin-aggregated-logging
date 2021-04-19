#!/bin/bash

set -euo pipefail
set -o xtrace

source $(dirname "$0")/ci-env.sh

# install Elasticsearch from zip distribution file
# put files in correct places in image
# fix up directory permissions and ownership
cd /var/tmp
ES_ARCHIVE_URL=${ES_ARCHIVE_URL:-${MAVEN_REPO_URL}org/elasticsearch/distribution/zip/elasticsearch-oss/${ES_VER}/elasticsearch-oss-${ES_VER}.zip}
curl -L -v -s -o es.zip ${ES_ARCHIVE_URL}
unzip es.zip
mv elasticsearch-$(echo $ES_VER | cut -d'.' -f1-3) elasticsearch-${ES_VER}
pushd elasticsearch-${ES_VER}
mkdir -p ${ES_HOME}/bin
install -p -m 755 bin/elasticsearch bin/elasticsearch-cli bin/elasticsearch-keystore \
    bin/elasticsearch-plugin bin/elasticsearch-shard bin/elasticsearch-translog ${ES_HOME}/bin
install -p -m 644 bin/elasticsearch-env ${ES_HOME}/bin
mkdir -p ${ES_HOME}/config
mkdir -p ${ES_HOME}/plugins
cp -r lib ${ES_HOME}
cp -r modules ${ES_HOME}
mkdir -p ${HOME}
chmod -R og+w ${ES_HOME} ${HOME}
mkdir -p ${ES_PATH_CONF}
chmod 2777 ${ES_PATH_CONF}
mkdir -p ${ES_PATH_CONF}/scripts
chmod 777 ${ES_PATH_CONF}/scripts
install -m 660 config/* ${ES_PATH_CONF}
popd
sed -i -e 's/^-Xms/#-Xms/' -e 's/^-Xmx/#-Xmx/' -e '/-Xlog/d' ${ES_PATH_CONF}/jvm.options
[[ `arch` = x86_64 ]] || sed -i -e '/UseAVX/d' ${ES_PATH_CONF}/jvm.options
cat extra-jvm.options >> ${ES_PATH_CONF}/jvm.options
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
mkdir /elasticsearch && chmod og+w /elasticsearch
rm -rf elasticsearch-$(echo $ES_VER | cut -d'.' -f1-3) es.zip extra-jvm.options

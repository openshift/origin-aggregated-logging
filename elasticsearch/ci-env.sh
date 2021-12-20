#!/bin/bash

set -o xtrace

#PROMETHEUS_EXPORTER_URL=${PROMETHEUS_EXPORTER_URL:-$MAVEN_REPO_URL/org/elasticsearch/plugin/prometheus/prometheus-exporter/$PROMETHEUS_EXPORTER_VER/prometheus-exporter-$PROMETHEUS_EXPORTER_VER.zip}
PROMETHEUS_EXPORTER_URL=file:///prometheus-exporter-$PROMETHEUS_EXPORTER_VER.zip
OPENDISTRO_URL=${OPENDISTRO_URL:-$MAVEN_REPO_URL/com/amazon/opendistroforelasticsearch/opendistro_security/$OPENDISTRO_VER/opendistro_security-$OPENDISTRO_VER.zip}

if [[ "${OPENSHIFT_CI:-}" == "true" ]]; then
    # This flag is set during CI runs. If no ARG was passed in,
    # default to maven.org.
    export ES_ARCHIVE_URL=https://github.com/ViaQ/elasticsearch/releases/download/elasticsearch-oss-$ES_VER/elasticsearch-oss-$ES_VER.zip
    export OPENDISTRO_URL=https://github.com/ViaQ/security/releases/download/opendistro_security-$OPENDISTRO_VER/opendistro_security-$OPENDISTRO_VER.zip
    export PROMETHEUS_EXPORTER_URL=https://github.com/vvanholl/elasticsearch-prometheus-exporter/releases/download/$PROMETHEUS_EXPORTER_VER/prometheus-exporter-$PROMETHEUS_EXPORTER_VER.zip
fi
es_plugins=($OPENDISTRO_URL $PROMETHEUS_EXPORTER_URL)

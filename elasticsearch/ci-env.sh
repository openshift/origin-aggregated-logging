#!/bin/bash

set -o xtrace

if [[ "${OPENSHIFT_CI:-}" == "true" ]]; then
    # This flag is set during CI runs. If no ARG was passed in,
    # default to maven.org.
	export RELEASE_STREAM=origin
    export ES_VER=6.8.1
    export PROMETHEUS_EXPORTER_VER=6.8.1.0
    export OPENDISTRO_VER=0.10.1.0
	export MAVEN_REPO_URL="https://repo1.maven.org/maven2/"
	export PROMETHEUS_EXPORTER_URL=https://github.com/vvanholl/elasticsearch-prometheus-exporter/releases/download/6.8.1.0/prometheus-exporter-6.8.1.0.zip
    export OPENDISTRO_URL=https://github.com/jcantrill/security/releases/download/v0.10.1.0/opendistro_security-0.10.1.0.zip
fi

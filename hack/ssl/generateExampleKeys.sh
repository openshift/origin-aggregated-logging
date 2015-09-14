#!/bin/bash
set -e
sh gen_root_ca.sh capass tspass
sh generateJKSChain.sh es-logging kspass capass && sh generatePEMCerts.sh fluentd-elasticsearch kspass capass && sh generatePEMCerts.sh kibana kspass capass
sh generateJKSChain.sh es-ops kspass capass && sh generatePEMCerts.sh kibana-ops kspass capass
cp ca/root-ca.crt fluentd-elasticsearch/
cp ca/root-ca.crt kibana/
cp truststore.jks es-logging/
cp ca/root-ca.crt kibana-ops/
cp truststore.jks es-ops/
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

#create searchguard_node_keys
openssl rand 16 | openssl enc -aes-128-cbc -nosalt -out es-logging/searchguard_node_key.key -pass pass:pass
openssl rand 16 | openssl enc -aes-128-cbc -nosalt -out es-ops/searchguard_node_key.key -pass pass:pass
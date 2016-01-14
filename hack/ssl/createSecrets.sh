#! /bin/bash

# clean up old secrets
echo "Cleaning up existing secrets"
oc delete secret fluentd
oc delete secret elasticsearch
oc delete secret kibana
oc delete secret elasticsearch-ops
oc delete secret kibana-ops

echo "Creating secrets..."
# create secret for fluentd
oc secrets new fluentd cert=$PWD/fluentd-elasticsearch/fluentd-elasticsearch.crt key=$PWD/fluentd-elasticsearch/fluentd-elasticsearch.key ca=$PWD/fluentd-elasticsearch/root-ca.crt

# create secret for ES
oc secrets new elasticsearch key=$PWD/es-logging/es-logging-keystore.jks truststore=$PWD/es-logging/truststore.jks searchguard.key=$PWD/es-logging/searchguard_node_key.key

# create secret for kibana
oc secrets new kibana cert=$PWD/kibana/kibana.crt key=$PWD/kibana/kibana.key ca=$PWD/kibana/root-ca.crt

# create secret for ES-ops
oc secrets new elasticsearch-ops key=$PWD/es-ops/es-ops-keystore.jks truststore=$PWD/es-ops/truststore.jks searchguard.key=$PWD/es-ops/searchguard_node_key.key

# create secret for kibana-ops
oc secrets new kibana-ops cert=$PWD/kibana-ops/kibana-ops.crt key=$PWD/kibana-ops/kibana-ops.key ca=$PWD/kibana-ops/root-ca.crt

echo "Assigning secrets to default"
# assign secrets to default for mount
oc secrets add serviceaccount/default secrets/fluentd --for=mount
oc secrets add serviceaccount/default secrets/elasticsearch --for=mount
oc secrets add serviceaccount/default secrets/kibana --for=mount

oc secrets add serviceaccount/default secrets/elasticsearch-ops --for=mount
oc secrets add serviceaccount/default secrets/kibana-ops --for=mount
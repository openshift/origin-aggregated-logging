#!/bin/bash
set -e
NODE_NAME=$1
KS_PASS=$2
CA_PASS=$3
rm -f $NODE_NAME
mkdir $NODE_NAME

echo Generating keystore and certificate for node $NODE_NAME

openssl req -out $NODE_NAME/$NODE_NAME.csr -new -newkey rsa:2048 -keyout $NODE_NAME/$NODE_NAME.key -subj '/CN=$NODE_NAME/OU=SSL/O=Test/L=Test/C=DE' -days 712 -nodes

echo Sign certificate request with CA
openssl ca \
    -in $NODE_NAME/$NODE_NAME.csr \
    -notext \
    -out $NODE_NAME/$NODE_NAME.crt \
    -config etc/signing-ca.conf \
    -extensions v3_req \
    -batch \
    -passin pass:$CA_PASS \
    -extensions server_ext

echo Cleaning up Cert Requests
rm -rf $NODE_NAME/$NODE_NAME.csr

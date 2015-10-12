#!/bin/bash
set -ex
NODE_NAME="$1"
dir=${SCRATCH_DIR:-_output}  # for writing files to bundle into secrets

echo Generating keystore and certificate for node ${NODE_NAME}

openssl req -out "$dir/$NODE_NAME.csr" -new -newkey rsa:2048 -keyout "$dir/$NODE_NAME.key" -subj "/CN=$NODE_NAME/OU=OpenShift/O=Logging/L=Test/C=DE" -days 712 -nodes 

echo Sign certificate request with CA
openssl ca \
    -in "$dir/$NODE_NAME.csr" \
    -notext \
    -out "$dir/$NODE_NAME.crt" \
    -config $dir/signing.conf \
    -extensions v3_req \
    -batch \
	-extensions server_ext


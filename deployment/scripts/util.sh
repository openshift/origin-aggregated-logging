#!/bin/bash

function generate_JKS_chain() {
  dir=${SCRATCH_DIR:-_output}
  NODE_NAME=$1
  CERT_NAMES=${2:-$NODE_NAME}
  ks_pass=${KS_PASS:-kspass}
  ts_pass=${TS_PASS:-tspass}
  rm -rf $NODE_NAME

  extension_names=""
  for name in ${CERT_NAMES//,/ }; do
	extension_names="${extension_names},dns:${name}"
  done

  echo Generating keystore and certificate for node $NODE_NAME

  "$JAVA_HOME/bin/keytool" -genkey \
        -alias     $NODE_NAME \
        -keystore  $dir/keystore.jks \
        -keypass   $ks_pass \
        -storepass $ks_pass \
        -keyalg    RSA \
        -keysize   2048 \
        -validity  712 \
        -dname "CN=$NODE_NAME, OU=SSL, O=Test, L=Test, C=DE" \
        -ext san=dns:localhost,ip:127.0.0.1"${extension_names}"

  echo Generating certificate signing request for node $NODE_NAME

  "$JAVA_HOME/bin/keytool" -certreq \
        -alias      $NODE_NAME \
        -keystore   $dir/keystore.jks \
        -storepass  $ks_pass \
        -file       $dir/$NODE_NAME.csr \
        -keyalg     rsa \
        -dname "CN=$NODE_NAME, OU=SSL, O=Test, L=Test, C=DE" \
        -ext san=dns:localhost,ip:127.0.0.1"${extension_names}"

  echo Sign certificate request with CA

  openssl ca \
    -in $dir/$NODE_NAME.csr \
    -notext \
    -out $dir/$NODE_NAME.crt \
    -config $dir/signing.conf \
    -extensions v3_req \
    -batch \
	-extensions server_ext

  echo "Import back to keystore (including CA chain)"

  "$JAVA_HOME/bin/keytool"  \
    -import \
    -file $dir/ca.crt  \
    -keystore $dir/keystore.jks   \
    -storepass $ks_pass  \
    -noprompt -alias sig-ca

  "$JAVA_HOME/bin/keytool" \
    -import \
    -file $dir/$NODE_NAME.crt \
    -keystore $dir/keystore.jks \
    -storepass $ks_pass \
    -noprompt \
    -alias $NODE_NAME

  echo "Import CA to truststore for validating client certs"

  "$JAVA_HOME/bin/keytool"  \
    -import \
    -file $dir/ca.crt  \
    -keystore $dir/truststore.jks   \
    -storepass $ts_pass  \
    -noprompt -alias sig-ca

  echo All done for $NODE_NAME
}

function generate_PEM_cert() {
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
}

function join { local IFS="$1"; shift; echo "$*"; }

function extract_nodeselector() {
  local inputstring="${1//\"/}"  # remove any errant double quotes in the inputs
  local selectors=()

  for keyvalstr in ${inputstring//\,/ }; do

    keyval=( ${keyvalstr//=/ } )

    if [[ -n "${keyval[0]}" && -n "${keyval[1]}" ]]; then
      selectors+=( "\"${keyval[0]}\": \"${keyval[1]}\"")
    else
      echo "Could not make a node selector label from '${keyval[*]}'"
      exit 255
    fi
  done

  if [[ "${#selectors[*]}" -gt 0 ]]; then
    echo nodeSelector: "{" $(join , "${selectors[@]}") "}"
  fi
}

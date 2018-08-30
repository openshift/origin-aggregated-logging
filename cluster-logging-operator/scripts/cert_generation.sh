#! /bin/bash

WORKING_DIR=${WORKING_DIR:-/tmp/_working_dir}
NAMESPACE=${NAMESPACE:-openshift-logging}
CA_PATH=${CA_PATH:-$WORKING_DIR/ca.crt}

function sign_cert() {
  local component=$1

  openssl ca \
          -in ${WORKING_DIR}/${component}.csr \
          -notext
          -out ${WORKING_DIR}/${component}.crt \
          -config ${WORKING_DIR}/signing.conf \
          -extensions v3_req \
          -batch \
          -extensions server_ext
}

function generate_cert_config() {
  local component=$1
  local extensions=${2:-}

  if [ "$extensions" != "" ]; then
    cat <<EOF > "${WORKING_DIR}/${component}.conf"
[ req ]
default_bits = 2048
prompt = no
encrypt_key = yes
default_md = sha1
distinguished_name = dn
req_extensions = req_ext
[ dn ]
CN = ${component}
OU = OpenShift
O = Logging
[ req_ext ]
subjectAltName = ${extensions}
EOF
  else
    cat <<EOF > "${WORKING_DIR}/${component}.conf"
[ req ]
default_bits = 2048
prompt = no
encrypt_key = yes
default_md = sha1
distinguished_name = dn
[ dn ]
CN = ${component}
OU = OpenShift
O = Logging
EOF
  fi
}

function generate_request() {
  local component=$1

  openssl req -new                                        \
          -out ${WORKING_DIR}/${component}.csr            \
          -newkey rsa:2048                                \
          -keyout ${WORKING_DIR}/${component}.key         \
          -config ${WORKING_DIR}/${component}.conf        \
          -days 712                                       \
          -nodes
}

function generate_certs() {
  local component=$1
  local extensions=${2:-}

  generate_cert_config $component $extensions
  generate_request $component
  sign_cert $component
}

function generate_extensions() {
  local add_oid=$1
  shift
  local cert_names=$@

  extension_names="IP.1:127.0.0.1,DNS.1:localhost"
  extension_index=2
  for name in ${cert_names//,/}; do
    extension_names="${extension_names},DNS.${extension_index}:${name}"
    extension_index=$(( extension_index + 1 ))
  done

  if [ "$add_oid" == "true" ]; then
    extension_names="${extension_names},RID.1:1.2.3.4.5.5"
  fi

  echo "$extension_names"
}

if [ ! -d $WORKING_DIR ]; then
  mkdir -p $WORKING_DIR
fi

generate_certs 'system.logging.fluentd'
generate_certs 'system.logging.kibana'
generate_certs 'system.logging.curator'
generate_certs 'system.admin'

generate_certs 'elasticsearch' "$(generate_extensions true logging-es{,-ops})"
generate_certs 'logging-es' "$(generate_extensions false logging-es{,-ops}{,-cluster}{,.${NAMESPACE}.svc.cluster.local})"

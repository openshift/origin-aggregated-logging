#!/bin/bash
set -ex

function install_logging() {
  initialize_install_vars
  generate_secrets
  generate_templates
  generate_objects
  notify_user
}

######################################
#
# initialize a lot of variables from env
#
function initialize_install_vars() {
  image_prefix=${IMAGE_PREFIX:-openshift/origin-}
  image_version=${IMAGE_VERSION:-latest}
  hostname=${KIBANA_HOSTNAME:-kibana.example.com}
  ops_hostname=${KIBANA_OPS_HOSTNAME:-kibana-ops.example.com}
  public_master_url=${PUBLIC_MASTER_URL:-https://kubernetes.default.svc.cluster.local:443}
  # ES cluster parameters:
  es_instance_ram=${ES_INSTANCE_RAM:-512M}
  es_pvc_size=${ES_PVC_SIZE:-}
  es_pvc_prefix=${ES_PVC_PREFIX:-}
  es_cluster_size=${ES_CLUSTER_SIZE:-1}
  es_node_quorum=${ES_NODE_QUORUM:-$((es_cluster_size/2+1))}
  es_recover_after_nodes=${ES_RECOVER_AFTER_NODES:-$((es_cluster_size-1))}
  es_recover_expected_nodes=${ES_RECOVER_EXPECTED_NODES:-$es_cluster_size}
  es_recover_after_time=${ES_RECOVER_AFTER_TIME:-5m}
  es_ops_instance_ram=${ES_OPS_INSTANCE_RAM:-512M}
  es_ops_pvc_size=${ES_OPS_PVC_SIZE:-}
  es_ops_pvc_prefix=${ES_OPS_PVC_PREFIX:-}
  es_ops_cluster_size=${ES_OPS_CLUSTER_SIZE:-$es_cluster_size}
  es_ops_node_quorum=${ES_OPS_NODE_QUORUM:-$((es_ops_cluster_size/2+1))}
  es_ops_recover_after_nodes=${ES_OPS_RECOVER_AFTER_NODES:-$((es_ops_cluster_size-1))}
  es_ops_recover_expected_nodes=${ES_OPS_RECOVER_EXPECTED_NODES:-$es_ops_cluster_size}
  es_ops_recover_after_time=${ES_OPS_RECOVER_AFTER_TIME:-5m}

  # other env vars used:
  # WRITE_KUBECONFIG, KEEP_SUPPORT, ENABLE_OPS_CLUSTER
  # *_NODESELECTOR
  # other env vars used (expect base64 encoding):
  # KIBANA_KEY, KIBANA_CERT, SERVER_TLS_JSON
} #initialize_install_vars()

function procure_server_cert() {
  local file=$1 hostnames=${2:-}
  if [ -s $secret_dir/$file.crt ]; then
    # use files from secret if present
    cp {$secret_dir,$dir}/$file.key
    cp {$secret_dir,$dir}/$file.crt
  elif [ -n "${hostnames:-}" ]; then  #fallback to creating one
    openshift admin ca create-server-cert  \
      --key=$dir/$file.key \
      --cert=$dir/$file.crt \
      --hostnames=${hostnames} \
      --signer-cert="$dir/ca.crt" --signer-key="$dir/ca.key" --signer-serial="$dir/ca.serial.txt"
  fi
}

function generate_support_objects() {

  oc delete template --selector logging-infra=support
  oc new-app -f templates/support.yaml \
     --param OAUTH_SECRET=$(cat $dir/oauth-secret) \
     --param KIBANA_HOSTNAME=${hostname} \
     --param KIBANA_OPS_HOSTNAME=${ops_hostname} \
     --param IMAGE_PREFIX_DEFAULT=${image_prefix}

  oc process logging-support-template | oc delete -f - || :
  oc delete imagestream,service,route --selector logging-infra=support
  # note: dev builds aren't labeled and won't be deleted. if you need to preserve imagestreams, you can just remove the label.
  # note: no automatic deletion of persistentvolumeclaim; didn't seem wise
  oc new-app logging-support-template
  kibana_keys=""; [ -e "$dir/kibana.crt" ] && kibana_keys="--cert=$dir/kibana.crt --key=$dir/kibana.key"
  oc create route reencrypt --service="logging-kibana" \
                             --hostname="${hostname}" \
                             --{dest-,}ca-cert="$dir/ca.crt" \
                                   $kibana_keys
  kibana_keys=""; [ -e "$dir/kibana-ops.crt" ] && kibana_keys="--cert=$dir/kibana-ops.crt --key=$dir/kibana-ops.key"
  oc create route reencrypt --service="logging-kibana-ops" \
                             --hostname="${ops_hostname}" \
                             --{dest-,}ca-cert="$dir/ca.crt" \
                                   $kibana_keys
   # note: route labels are copied from service, no need to add
}

function generate_signer_cert_and_conf() {
  # this fails in the container, but it's useful for dev
  rm -rf $dir && mkdir -p $dir && chmod 700 $dir || :
  mkdir -p $secret_dir && chmod 700 $secret_dir || :

  # cp/generate CA
  if [ -s $secret_dir/ca.key ]; then
    cp {$secret_dir,$dir}/ca.key
    cp {$secret_dir,$dir}/ca.crt
    echo "01" > $dir/ca.serial.txt
  else
    openshift admin ca create-signer-cert  \
      --key="${dir}/ca.key" \
      --cert="${dir}/ca.crt" \
      --serial="${dir}/ca.serial.txt" \
      --name="logging-signer-$(date +%Y%m%d%H%M%S)"
  fi

  echo Generating signing configuration file
  cat - conf/signing.conf > $dir/signing.conf <<CONF
[ default ]
dir                     = ${dir}               # Top dir
CONF
}

######################################
#
# generate secret contents and secrets
#
function generate_secrets() {
  if [ "${KEEP_SUPPORT}" != true ]; then
    generate_signer_cert_and_conf

    # use or generate Kibana proxy certs
    procure_server_cert kibana       # external cert, use router cert if not present
    procure_server_cert kibana-ops   # second external cert
    procure_server_cert kibana-internal kibana,kibana-ops,${hostname},${ops_hostname}

    # use or copy proxy TLS configuration file
    if [ -s $secret_dir/server-tls.json ]; then
      cp $secret_dir/server-tls.json $dir
    else
      cp conf/server-tls.json $dir
    fi

    # generate client certs for accessing ES
    cat /dev/null > $dir/ca.db
    cat /dev/null > $dir/ca.crt.srl
    fluentd_user='system.logging.fluentd'
    kibana_user='system.logging.kibana'
    curator_user='system.logging.curator'
    admin_user='system.admin'
    generate_PEM_cert "$fluentd_user"
    generate_PEM_cert "$kibana_user"
    generate_PEM_cert "$curator_user"
    generate_PEM_cert "$admin_user"

    # generate java store/trust for the ES SearchGuard plugin
    generate_JKS_chain logging-es "$(join , logging-es{,-ops}{,-cluster}{,.${project}.svc.cluster.local})"
    # generate common node key for the SearchGuard plugin
    openssl rand 16 | openssl enc -aes-128-cbc -nosalt -out $dir/searchguard_node_key.key -pass pass:pass

    # generate proxy session
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 200 | head -n 1 > "$dir/session-secret"
    # generate oauth client secret
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1 > "$dir/oauth-secret"

    # (re)generate secrets
    echo "Deleting existing secrets"
    oc delete secret logging-fluentd logging-elasticsearch logging-kibana logging-kibana-proxy logging-kibana-ops-proxy logging-curator logging-curator-ops || :

    echo "Creating secrets"
    oc secrets new logging-elasticsearch \
        key=$dir/keystore.jks truststore=$dir/truststore.jks \
        searchguard.key=$dir/searchguard_node_key.key \
        admin-key=$dir/${admin_user}.key admin-cert=$dir/${admin_user}.crt \
        admin-ca=$dir/ca.crt
    oc secrets new logging-kibana \
        ca=$dir/ca.crt \
        key=$dir/${kibana_user}.key cert=$dir/${kibana_user}.crt
    oc secrets new logging-kibana-proxy \
        oauth-secret=$dir/oauth-secret \
        session-secret=$dir/session-secret \
        server-key=$dir/kibana-internal.key \
        server-cert=$dir/kibana-internal.crt \
        server-tls.json=$dir/server-tls.json
    oc secrets new logging-fluentd \
        ca=$dir/ca.crt \
        key=$dir/${fluentd_user}.key cert=$dir/${fluentd_user}.crt
    oc secrets new logging-curator \
        ca=$dir/ca.crt \
        key=$dir/${curator_user}.key cert=$dir/${curator_user}.crt
    oc secrets new logging-curator-ops \
        ca=$dir/ca.crt \
        key=$dir/${curator_user}.key cert=$dir/${curator_user}.crt
    echo "Attaching secrets to service accounts"
    oc secrets add serviceaccount/aggregated-logging-kibana \
                   logging-kibana logging-kibana-proxy
    oc secrets add serviceaccount/aggregated-logging-elasticsearch \
                   logging-elasticsearch
    oc secrets add serviceaccount/aggregated-logging-fluentd \
                   logging-fluentd
    oc secrets add serviceaccount/aggregated-logging-curator \
                   logging-curator

    # this does seem a little out of place for the scope of this function
    # but this is being placed here to avoid the support template being out of sync
    # with a la carte installations
    # if we are regenerating certificates we *need* to rebuild our support template/objects
    generate_support_objects
  fi # supporting infrastructure - secrets
}

function create_template_optional_nodeselector(){
  local nodeselector="${1:-}"; shift
  local template="$1"; shift
  cp {templates,$dir}/${template}.yaml
  # remaining params are for the template
  [[ -n "${nodeselector}" ]] && sed "/serviceAccountName/ i\
\          $(extract_nodeselector $nodeselector)" templates/${template}.yaml > $dir/${template}.yaml
  oc new-app -f $dir/${template}.yaml $@
}

function generate_es_template(){
  oc delete template --selector logging-infra=elasticsearch

  create_template_optional_nodeselector "${ES_NODESELECTOR}" es \
    --param ES_CLUSTER_NAME=es \
    --param ES_INSTANCE_RAM=${es_instance_ram} \
    --param ES_NODE_QUORUM=${es_node_quorum} \
    --param ES_RECOVER_AFTER_NODES=${es_recover_after_nodes} \
    --param ES_RECOVER_EXPECTED_NODES=${es_recover_expected_nodes} \
    --param ES_RECOVER_AFTER_TIME=${es_recover_after_time} \
    --param IMAGE_VERSION_DEFAULT=${image_version}

    if [ "${ENABLE_OPS_CLUSTER}" == true ]; then
      create_template_optional_nodeselector "${ES_OPS_NODESELECTOR}" es \
        --param ES_CLUSTER_NAME=es-ops \
        --param ES_INSTANCE_RAM=${es_ops_instance_ram} \
        --param ES_NODE_QUORUM=${es_ops_node_quorum} \
        --param ES_RECOVER_AFTER_NODES=${es_ops_recover_after_nodes} \
        --param ES_RECOVER_EXPECTED_NODES=${es_ops_recover_expected_nodes} \
        --param ES_RECOVER_AFTER_TIME=${es_ops_recover_after_time} \
        --param IMAGE_VERSION_DEFAULT=${image_version}
    fi
}

function generate_kibana_template(){
  oc delete template --selector logging-infra=kibana

  create_template_optional_nodeselector "${KIBANA_NODESELECTOR}" kibana \
    --param OAP_PUBLIC_MASTER_URL=${public_master_url} \
    --param OAP_MASTER_URL=${master_url} \
    --param IMAGE_VERSION_DEFAULT=${image_version}

    if [ "${ENABLE_OPS_CLUSTER}" == true ]; then
      create_template_optional_nodeselector "${KIBANA_OPS_HOSTNAME_OPS_NODESELECTOR}" kibana \
        --param OAP_PUBLIC_MASTER_URL=${public_master_url} \
        --param OAP_MASTER_URL=${master_url} \
        --param KIBANA_DEPLOY_NAME=kibana-ops \
        --param ES_HOST=logging-es-ops \
        --param IMAGE_VERSION_DEFAULT=${image_version}
    fi
}

function generate_curator_template(){
  oc delete template --selector logging-infra=curator

  create_template_optional_nodeselector "${CURATOR_NODESELECTOR}" curator \
    --param ES_HOST=logging-es \
    --param MASTER_URL=${master_url} \
    --param CURATOR_DEPLOY_NAME=curator \
    --param IMAGE_VERSION_DEFAULT=${image_version}

  if [ "${ENABLE_OPS_CLUSTER}" == true ]; then
    create_template_optional_nodeselector "${CURATOR_OPS_NODESELECTOR}" curator \
      --param ES_HOST=logging-es-ops \
      --param MASTER_URL=${master_url} \
      --param CURATOR_DEPLOY_NAME=curator-ops \
      --param IMAGE_VERSION_DEFAULT=${image_version}
  fi
}

function generate_fluentd_template(){
  oc delete template --selector logging-infra=fluentd

  es_host=logging-es
  es_ops_host=${es_host}
  if [ "${ENABLE_OPS_CLUSTER}" == true ]; then
    es_ops_host=logging-es-ops
  fi

  create_template_optional_nodeselector "${FLUENTD_NODESELECTOR}" fluentd \
    --param ES_HOST=${es_host} \
    --param OPS_HOST=${es_ops_host} \
    --param MASTER_URL=${master_url} \
    --param IMAGE_PREFIX_DEFAULT=${image_prefix} \
    --param IMAGE_VERSION_DEFAULT=${image_version}
}

######################################
#
# (re)generate templates needed
#
function generate_templates() {
  echo "(Re-)Creating templates"
  generate_es_template
  generate_kibana_template
  generate_curator_template
  generate_fluentd_template
} #generate_templates()

function generate_curator() {
  oc delete dc,rc,pod --selector logging-infra=curator

  oc new-app logging-curator-template
  if [ "${ENABLE_OPS_CLUSTER}" == true ]; then
    oc new-app logging-curator-ops-template
  fi
}

function generate_kibana() {
  oc delete dc,rc,pod --selector logging-infra=kibana

  oc new-app logging-kibana-template
  if [ "${ENABLE_OPS_CLUSTER}" == true ]; then
    oc new-app logging-kibana-ops-template
  fi
}

function generate_fluentd() {
  oc delete dc,rc,pod,daemonset --selector logging-infra=fluentd

  oc new-app logging-fluentd-template
}

function generate_es() {
  oc delete dc,rc,pod --selector logging-infra=elasticsearch

  declare -A pvcs=()
  for pvc in $(oc get persistentvolumeclaim --template='{{range .items}}{{.metadata.name}} {{end}}' 2>/dev/null); do
    pvcs["$pvc"]=1  # note, map all that exist, not just ones labeled as supporting
  done
  for ((n=1;n<=${es_cluster_size};n++)); do
    pvc="${ES_PVC_PREFIX}$n"
    if [ "${pvcs[$pvc]}" != 1 -a "${ES_PVC_SIZE}" != "" ]; then # doesn't exist, create it
      oc new-app logging-pvc-template -p "NAME=$pvc,SIZE=${ES_PVC_SIZE}"
      pvcs["$pvc"]=1
    fi
    if [ "${pvcs[$pvc]}" = 1 ]; then # exists (now), attach it
      oc process logging-es-template | \
        oc volume -f - \
                  --add --overwrite --name=elasticsearch-storage \
                  --type=persistentVolumeClaim --claim-name="$pvc"
    else
      oc new-app logging-es-template
    fi
  done

  if [ "${ENABLE_OPS_CLUSTER}" == true ]; then
    for ((n=1;n<=${es_ops_cluster_size};n++)); do
      pvc="${ES_OPS_PVC_PREFIX}$n"
      if [ "${pvcs[$pvc]}" != 1 -a "${ES_OPS_PVC_SIZE}" != "" ]; then # doesn't exist, create it
        oc new-app logging-pvc-template -p "NAME=$pvc,SIZE=${ES_OPS_PVC_SIZE}"
        pvcs["$pvc"]=1
      fi
      if [ "${pvcs[$pvc]}" = 1 ]; then # exists (now), attach it
            oc process logging-es-ops-template | oc volume -f - \
                  --add --overwrite --name=elasticsearch-storage \
                  --type=persistentVolumeClaim --claim-name="$pvc"
      else
            oc new-app logging-es-ops-template
      fi
    done
  fi
}

######################################
#
# Create "things", mostly from templates
#
function generate_objects() {
  echo "(Re-)Creating deployed objects"
  oc new-app logging-imagestream-template || : # these may fail if created independently; that's ok

  generate_es
  generate_kibana
  generate_curator
  generate_fluentd
} #generate_objects()

######################################
#
# Give the user some helpful output
#
function notify_user() {
  set +x
  echo 'Success!'
  fns=${FLUENTD_NODESELECTOR:-logging-infra-fluentd=true}
  ops_cluster_section=""
  if [ "${ENABLE_OPS_CLUSTER}" == true ]; then
    ops_cluster_section="
Operations logs:
----------------
You chose to split ops logs to their own ops cluster, which includes an
ElasticSearch cluster and its own deployment of Kibana. The deployments
are set apart by '-ops' in the name. The comments above about configuring
ES deployments apply equally to the ops cluster.
"
  fi

  cat <<EOF

=================================

The deployer has created secrets, templates, and component deployments
required for logging. You now have a few more steps to run manually.
Consult the deployer docs for more detail.

ElasticSearch:
--------------
Clustered instances have been created as individual deployments. View with:
    oc get dc --selector logging-infra=elasticsearch

Your deployments will likely need to specify persistent storage volumes
and node selectors. It's best to do this before spinning up fluentd.
To attach persistent storage, you can modify each deployment through
'oc volume'.

Fluentd:
--------------
Fluentd is deployed to nodes via a DaemonSet. Label the nodes to deploy it to:
    oc label node/<node-name> ${fns}

To label all nodes at once:
    oc label nodes --all ${fns}
${ops_cluster_section}
EOF
} #notify_user()

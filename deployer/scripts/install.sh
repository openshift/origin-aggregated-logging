#!/bin/bash
set -ex

function delete_logging() {
  initialize_install_vars
  echo "Deleting all other logging objects"
  oc process logging-support-template | oc delete -f - || :
  oc delete dc,rc,svc,routes,templates,daemonset --selector logging-infra
  oc delete is -l logging-infra=support
  # secrets don't have label selectors
  oc delete secret logging-fluentd logging-elasticsearch logging-kibana logging-kibana-proxy logging-curator logging-curator-ops || :
}

function install_logging() {
  initialize_install_vars
  generate_config
  generate_support_objects
  generate_templates
  generate_objects
  notify_user
}

######################################
#
# initialize a lot of variables from env
#
declare -A input_vars=()
function initialize_install_vars() {
  set +x
  local configmap secret index value var
  local index_template='{{range $index, $element :=.data}}{{println $index}}{{end}}'
  # if configmap exists, get values from it
  if configmap=$(oc get configmap/logging-deployer --template="$index_template"); then
    for index in $configmap; do
      input_vars[$index]=$(oc get configmap/logging-deployer --template="{{println (index .data \"$index\")}}")
    done
  fi
  # if secret exists, get values from it
  if secret=$(oc get secret/logging-deployer --template="$index_template"); then
    for index in $secret; do
      : ${input_vars[$index]:=$(oc get secret/logging-deployer --template="{{println (index .data \"$index\")}}" | base64 -d)}
    done
  fi
  # if legacy variables set, use them to fill unset inputs
  for var in KIBANA_HOSTNAME KIBANA_OPS_HOSTNAME PUBLIC_MASTER_URL ENABLE_OPS_CLUSTER IMAGE_PULL_SECRET \
             ES{_OPS,}_{INSTANCE_RAM,PVC_SIZE,PVC_PREFIX,PVC_DYNAMIC,CLUSTER_SIZE,NODE_QUORUM,RECOVER_AFTER_NODES,RECOVER_EXPECTED_NODES,RECOVER_AFTER_TIME} \
             {ES,ES_OPS,KIBANA,KIBANA_OPS,CURATOR,CURATOR_OPS,FLUENTD}_NODESELECTOR
  do
    [ ${!var+set} ] || continue
    index=${var,,} # lowercase
    index=${index//_/-} # underscore to hyphen
    : ${input_vars[$index]:=${!var}}
  done
  set -x

  insecure_registry=${input_vars[insecure-registry]:-false}
  hostname=${input_vars[kibana-hostname]:-kibana.example.com}
  ops_hostname=${input_vars[kibana-ops-hostname]:-kibana-ops.example.com}
  public_master_url=${input_vars[public-master-url]:-https://kubernetes.default.svc.cluster.local:443}
  # ES cluster parameters:
  es_instance_ram=${input_vars[es-instance-ram]:-512M}
  es_pvc_size=${input_vars[es-pvc-size]:-}
  es_pvc_prefix=${input_vars[es-pvc-prefix]:-}
  es_pvc_dynamic=${input_vars[es-pvc-dynamic]:-}
  es_cluster_size=${input_vars[es-cluster-size]:-1}
  es_node_quorum=${input_vars[es-node-quorum]:-$((es_cluster_size/2+1))}
  es_recover_after_nodes=${input_vars[es-recover-after-nodes]:-$((es_cluster_size-1))}
  es_recover_expected_nodes=${input_vars[es-recover-expected-nodes]:-$es_cluster_size}
  es_recover_after_time=${input_vars[es-recover-after-time]:-5m}
  es_ops_instance_ram=${input_vars[es-ops-instance-ram]:-512M}
  es_ops_pvc_size=${input_vars[es-ops-pvc-size]:-}
  es_ops_pvc_prefix=${input_vars[es-ops-pvc-prefix]:-}
  es_ops_pvc_dynamic=${input_vars[es-ops-pvc-dynamic]:-}
  es_ops_cluster_size=${input_vars[es-ops-cluster-size]:-$es_cluster_size}
  es_ops_node_quorum=${input_vars[es-ops-node-quorum]:-$((es_ops_cluster_size/2+1))}
  es_ops_recover_after_nodes=${input_vars[es-ops-recover-after-nodes]:-$((es_ops_cluster_size-1))}
  es_ops_recover_expected_nodes=${input_vars[es-ops-recover-expected-nodes]:-$es_ops_cluster_size}
  es_ops_recover_after_time=${input_vars[es-ops-recover-after-time]:-5m}

  # other env vars used:
  # WRITE_KUBECONFIG, KEEP_SUPPORT, ENABLE_OPS_CLUSTER
  # *_NODESELECTOR

  image_prefix=${IMAGE_PREFIX:-openshift/origin-}
  image_version=${IMAGE_VERSION:-latest}
  # if env vars defined, get values from them
  # special-casing this as it's required anywhere we create a DC,
  # including both installs and upgrades. so ensure it's always set.
  image_params="IMAGE_VERSION_DEFAULT=${image_version},IMAGE_PREFIX_DEFAULT=${image_prefix}"
} #initialize_install_vars()

function procure_server_cert() {
  local file=$1 hostnames=${2:-}
  if [ ${input_vars[$file.crt]+set} ]; then
    # use files from secret if present
    echo -e "${input_vars[$file.key]}" > $dir/$file.key
    echo -e "${input_vars[$file.crt]}" > $dir/$file.crt
  elif [ -n "${hostnames:-}" ]; then  #fallback to creating one
    openshift admin ca create-server-cert  \
      --key=$dir/$file.key \
      --cert=$dir/$file.crt \
      --hostnames=${hostnames} \
      --signer-cert="$dir/ca.crt" --signer-key="$dir/ca.key" --signer-serial="$dir/ca.serial.txt"
  fi
}

function generate_support_objects() {

  oc new-app -f templates/support.yaml \
     --param OAUTH_SECRET=$(cat $dir/oauth-secret) \
     --param KIBANA_HOSTNAME=${hostname} \
     --param KIBANA_OPS_HOSTNAME=${ops_hostname} \
     --param IMAGE_PREFIX_DEFAULT=${image_prefix} \
     --param IMAGE_VERSION_DEFAULT=${image_version}

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

  # cp/generate CA
  if [ ${input_vars[ca.key]+set} ]; then
    echo -e "${input_vars[ca.key]}" > $dir/ca.key
    echo -e "${input_vars[ca.crt]}" > $dir/ca.crt
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
# generate secret contents, secrets, and configmaps
#
function generate_config() {
    generate_signer_cert_and_conf

    # use or generate Kibana proxy certs
    procure_server_cert kibana       # external cert, use router cert if not present
    procure_server_cert kibana-ops   # second external cert
    procure_server_cert kibana-internal kibana,kibana-ops,${hostname},${ops_hostname}

    # use or copy proxy TLS configuration file
    if [ ${input_vars[server-tls.json]+set} ]; then
      echo -e "${input_var[server-tls.json]}" $dir/server-tls.json
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
    echo "Deleting secrets"
    oc delete secret logging-fluentd logging-elasticsearch logging-kibana logging-kibana-proxy logging-curator logging-curator-ops || :

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
    if [ -n "${input_vars[image-pull-secret]}" ]; then
      for account in default aggregated-logging-{elasticsearch,fluentd,kibana,curator}; do
        oc secrets add --for=pull "serviceaccount/$account" "secret/${input_vars[image-pull-secret]}"
      done
    fi

    generate_configmaps
}

function generate_configmaps() {
    ### ConfigMaps
    echo "Deleting configmaps"
    oc delete configmap -l logging-infra=support

    echo "Creating configmaps"

    # generate elasticsearch configmap
    oc create configmap logging-elasticsearch \
      --from-file=common/elasticsearch/logging.yml \
      --from-file=conf/elasticsearch.yml
    oc label configmap/logging-elasticsearch logging-infra=support # make easier to delete later

    # generate curator configmap
    oc create configmap logging-curator \
      --from-file=config.yaml=conf/curator.yml
    oc label configmap/logging-curator logging-infra=support # make easier to delete later

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

  create_template_optional_nodeselector "${input_vars[es-nodeselector]}" es \
    --param ES_CLUSTER_NAME=es \
    --param ES_INSTANCE_RAM=${es_instance_ram} \
    --param ES_NODE_QUORUM=${es_node_quorum} \
    --param ES_RECOVER_AFTER_NODES=${es_recover_after_nodes} \
    --param ES_RECOVER_EXPECTED_NODES=${es_recover_expected_nodes} \
    --param ES_RECOVER_AFTER_TIME=${es_recover_after_time} \
    --param "$image_params"

    if [ "${input_vars[enable-ops-cluster]}" == true ]; then
      create_template_optional_nodeselector "${input_vars[es-ops-nodeselector]}" es \
        --param ES_CLUSTER_NAME=es-ops \
        --param ES_INSTANCE_RAM=${es_ops_instance_ram} \
        --param ES_NODE_QUORUM=${es_ops_node_quorum} \
        --param ES_RECOVER_AFTER_NODES=${es_ops_recover_after_nodes} \
        --param ES_RECOVER_EXPECTED_NODES=${es_ops_recover_expected_nodes} \
        --param ES_RECOVER_AFTER_TIME=${es_ops_recover_after_time} \
        --param "$image_params"
    fi
}

function generate_kibana_template(){
  create_template_optional_nodeselector "${input_vars[kibana-nodeselector]}" kibana \
    --param OAP_PUBLIC_MASTER_URL=${public_master_url} \
    --param OAP_MASTER_URL=${master_url} \
    --param "$image_params"

    if [ "${input_vars[enable-ops-cluster]}" == true ]; then
      create_template_optional_nodeselector "${input_vars[kibana-ops-nodeselector]}" kibana \
        --param OAP_PUBLIC_MASTER_URL=${public_master_url} \
        --param OAP_MASTER_URL=${master_url} \
        --param KIBANA_DEPLOY_NAME=kibana-ops \
        --param ES_HOST=logging-es-ops \
        --param "$image_params"
    fi
}

function generate_curator_template(){
  create_template_optional_nodeselector "${input_vars[curator-nodeselector]}" curator \
    --param ES_HOST=logging-es \
    --param MASTER_URL=${master_url} \
    --param CURATOR_DEPLOY_NAME=curator \
    --param "$image_params"

  if [ "${input_vars[enable-ops-cluster]}" == true ]; then
    create_template_optional_nodeselector "${input_vars[curator-ops-nodeselector]}" curator \
      --param ES_HOST=logging-es-ops \
      --param MASTER_URL=${master_url} \
      --param CURATOR_DEPLOY_NAME=curator-ops \
      --param "$image_params"
  fi
}

function generate_fluentd_template(){
  es_host=logging-es
  es_ops_host=${es_host}
  if [ "${input_vars[enable-ops-cluster]}" == true ]; then
    es_ops_host=logging-es-ops
  fi

  create_template_optional_nodeselector "${input_vars[fluentd-nodeselector]}" fluentd \
    --param ES_HOST=${es_host} \
    --param OPS_HOST=${es_ops_host} \
    --param MASTER_URL=${master_url} \
    --param "$image_params"
} #generate_fluentd_template()

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
  oc new-app logging-curator-template
  if [ "${input_vars[enable-ops-cluster]}" == true ]; then
    oc new-app logging-curator-ops-template
  fi
}

function generate_kibana() {
  oc new-app logging-kibana-template
  if [ "${input_vars[enable-ops-cluster]}" == true ]; then
    oc new-app logging-kibana-ops-template
  fi
}

function generate_fluentd() {
  oc new-app logging-fluentd-template
}

function generate_es() {
  declare -A pvcs=()
  for pvc in $(oc get persistentvolumeclaim --template='{{range .items}}{{.metadata.name}} {{end}}' 2>/dev/null); do
    pvcs["$pvc"]=1  # note, map all that exist, not just ones labeled as supporting
  done
  for ((n=1;n<=${es_cluster_size};n++)); do
    pvc="${ES_PVC_PREFIX}$n"
    if [ "${pvcs[$pvc]}" != 1 -a "${ES_PVC_SIZE}" != "" ]; then # doesn't exist, create it
      oc new-app logging-pvc-${es_pvc_dynamic:+"dynamic-"}template -p "NAME=$pvc,SIZE=${ES_PVC_SIZE}"
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

  if [ "${input_vars[enable-ops-cluster]}" == true ]; then
    for ((n=1;n<=${es_ops_cluster_size};n++)); do
      pvc="${ES_OPS_PVC_PREFIX}$n"
      if [ "${pvcs[$pvc]}" != 1 -a "${ES_OPS_PVC_SIZE}" != "" ]; then # doesn't exist, create it
        oc new-app logging-pvc-${es_ops_pvc_dynamic:+"dynamic-"}template -p "NAME=$pvc,SIZE=${ES_OPS_PVC_SIZE}"
        pvcs["$pvc"]=1
      fi
      if [ "${pvcs[$pvc]}" = 1 ]; then # exists (now), attach it
            oc process logging-es-ops-template | \
              oc volume -f - \
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

  generate_es
  generate_kibana
  generate_curator
  generate_fluentd

  for dc in $(oc get dc -l logging-infra -o name); do
    oc deploy $dc --latest
  done
} #generate_objects()

######################################
#
# Give the user some helpful output
#
function notify_user() {
  set +x
  echo 'Success!'
  fns=${input_vars[fluentd_nodeselector]:-logging-infra-fluentd=true}
  ops_cluster_section=""
  if [ "${input_vars[enable-ops-cluster]}" == true ]; then
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

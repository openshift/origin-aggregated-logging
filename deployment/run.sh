#!/bin/bash
set -ex
dir=${SCRATCH_DIR:-_output}  # for writing files to bundle into secrets
image_prefix=${IMAGE_PREFIX:-openshift/}
image_version=${IMAGE_VERSION:-latest}
hostname=${KIBANA_HOSTNAME:-kibana.example.com}
ops_hostname=${KIBANA_OPS_HOSTNAME:-kibana-ops.example.com}
public_master_url=${PUBLIC_MASTER_URL:-https://kubernetes.default.svc.cluster.local:443}
project=${PROJECT:-default}
# only needed for writing a kubeconfig:
master_url=${MASTER_URL:-https://kubernetes.default.svc.cluster.local:443}
master_ca=${MASTER_CA:-/var/run/secrets/kubernetes.io/serviceaccount/ca.crt}
token_file=${TOKEN_FILE:-/var/run/secrets/kubernetes.io/serviceaccount/token}
# ES cluster parameters:
es_instance_ram=${ES_INSTANCE_RAM:-512M}
es_cluster_size=${ES_CLUSTER_SIZE:-1}
es_node_quorum=${ES_NODE_QUORUM:-$((es_cluster_size/2+1))}
es_recover_after_nodes=${ES_RECOVER_AFTER_NODES:-$((es_cluster_size-1))}
es_recover_expected_nodes=${ES_RECOVER_EXPECTED_NODES:-$es_cluster_size}
es_recover_after_time=${ES_RECOVER_AFTER_TIME:-5m}
es_ops_instance_ram=${ES_OPS_INSTANCE_RAM:-512M}
es_ops_cluster_size=${ES_OPS_CLUSTER_SIZE:-$es_cluster_size}
es_ops_node_quorum=${ES_OPS_NODE_QUORUM:-$((es_ops_cluster_size/2+1))}
es_ops_recover_after_nodes=${ES_OPS_RECOVER_AFTER_NODES:-$((es_ops_cluster_size-1))}
es_ops_recover_expected_nodes=${ES_OPS_RECOVER_EXPECTED_NODES:-$es_ops_cluster_size}
es_ops_recover_after_time=${ES_OPS_RECOVER_AFTER_TIME:-5m}

# other env vars used:
# WRITE_KUBECONFIG, KEEP_SUPPORT, ENABLE_OPS_CLUSTER
# other env vars used (expect base64 encoding):
# KIBANA_KEY, KIBANA_CERT, SERVER_TLS_JSON

function join { local IFS="$1"; shift; echo "$*"; }

if [ "${KEEP_SUPPORT}" != true ]; then
	# this fails in the container, but it's useful for dev
	rm -rf $dir && mkdir -p $dir && chmod 700 $dir || :
fi

# set up configuration for openshift client
if [ -n "${WRITE_KUBECONFIG}" ]; then
    # craft a kubeconfig, usually at $KUBECONFIG location
    oc config set-cluster master \
	--api-version='v1' \
	--certificate-authority="${master_ca}" \
	--server="${master_url}"
    oc config set-credentials account \
	--token="$(cat ${token_file})"
    oc config set-context current \
	--cluster=master \
	--user=account \
	--namespace="${project}"
    oc config use-context current
fi

if [ "${KEEP_SUPPORT}" != true ]; then
	# cp/generate CA
	if [ -s /secret/ca.key ]; then
		cp {/secret,$dir}/ca.key
		cp {/secret,$dir}/ca.crt
		echo "01" > $dir/ca.serial.txt
	else
	    openshift admin ca create-signer-cert  \
	      --key="${dir}/ca.key" \
	      --cert="${dir}/ca.crt" \
	      --serial="${dir}/ca.serial.txt" \
	      --name="logging-signer-$(date +%Y%m%d%H%M%S)"
	fi

	# use or generate Kibana proxy certs
	if [ -n "${KIBANA_KEY}" ]; then
		echo "${KIBANA_KEY}" | base64 -d > $dir/kibana.key
		echo "${KIBANA_CERT}" | base64 -d > $dir/kibana.crt
	elif [ -s /secret/kibana.crt ]; then
		# use files from secret if present
		cp {/secret,$dir}/kibana.key
		cp {/secret,$dir}/kibana.crt
	else #fallback to creating one
	    openshift admin ca create-server-cert  \
	      --key=$dir/kibana.key \
	      --cert=$dir/kibana.crt \
	      --hostnames=kibana,${hostname},${ops_hostname} \
	      --signer-cert="$dir/ca.crt" --signer-key="$dir/ca.key" --signer-serial="$dir/ca.serial.txt"
	fi
	if [ -s /secret/kibana-ops.crt ]; then
		# use files from secret if present
		cp {/secret,$dir}/kibana-ops.key
		cp {/secret,$dir}/kibana-ops.crt
	else # just reuse the regular kibana cert
		cp $dir/kibana{,-ops}.key
		cp $dir/kibana{,-ops}.crt
	fi

	echo 03 > $dir/ca.serial.txt  # otherwise openssl chokes on the file
	echo Generating signing configuration file
	cat - conf/signing.conf > $dir/signing.conf <<CONF
[ default ]
dir                     = ${dir}               # Top dir
CONF

	# use or copy proxy TLS configuration file
	if [ -n "${SERVER_TLS_JSON}" ]; then
		echo "${SERVER_TLS_JSON}" | base64 -d > $dir/server-tls.json
	elif [ -s /secret/server-tls.json ]; then
		cp /secret/server-tls.json $dir
	else
		cp conf/server-tls.json $dir
	fi

	# generate client certs for accessing ES
	cat /dev/null > $dir/ca.db
	cat /dev/null > $dir/ca.crt.srl
	fluentd_user='system.logging.fluentd'
	kibana_user='system.logging.kibana'
	sh scripts/generatePEMCert.sh "$fluentd_user"
	sh scripts/generatePEMCert.sh "$kibana_user"

	# generate java store/trust for the ES SearchGuard plugin
	sh scripts/generateJKSChain.sh logging-es "$(join , logging-es{,-ops}{,-cluster}{,.${project}.svc.cluster.local})"
	# generate common node key for the SearchGuard plugin
	openssl rand 16 | openssl enc -aes-128-cbc -nosalt -out $dir/searchguard_node_key.key -pass pass:pass

	# generate proxy session
	cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 200 | head -n 1 > "$dir/session-secret"
	# generate oauth client secret
	cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1 > "$dir/oauth-secret"

	# (re)generate secrets
	echo "Deleting existing secrets"
	oc delete secret logging-fluentd logging-elasticsearch logging-kibana logging-kibana-proxy logging-kibana-ops-proxy || :

	echo "Creating secrets"
	oc secrets new logging-elasticsearch \
	    key=$dir/keystore.jks truststore=$dir/truststore.jks \
	    searchguard.key=$dir/searchguard_node_key.key
	oc secrets new logging-kibana \
	    ca=$dir/ca.crt \
	    key=$dir/${kibana_user}.key cert=$dir/${kibana_user}.crt
	oc secrets new logging-kibana-proxy \
	    oauth-secret=$dir/oauth-secret \
	    session-secret=$dir/session-secret \
	    server-key=$dir/kibana.key \
	    server-cert=$dir/kibana.crt \
	    server-tls.json=$dir/server-tls.json
	oc secrets new logging-kibana-ops-proxy \
	    oauth-secret=$dir/oauth-secret \
	    session-secret=$dir/session-secret \
	    server-key=$dir/kibana-ops.key \
	    server-cert=$dir/kibana-ops.crt \
	    server-tls.json=$dir/server-tls.json
	oc secrets new logging-fluentd \
	    ca=$dir/ca.crt \
	    key=$dir/${fluentd_user}.key cert=$dir/${fluentd_user}.crt

fi # supporting infrastructure

# (re)generate templates needed
echo "Creating templates"
oc delete template --selector logging-infra=kibana
oc delete template --selector logging-infra=fluentd
oc delete template --selector logging-infra=elasticsearch

es_params=$(join , \
	ES_CLUSTER_NAME=es \
	ES_INSTANCE_RAM=${es_instance_ram} \
	ES_NODE_QUORUM=${es_node_quorum} \
	ES_RECOVER_AFTER_NODES=${es_recover_after_nodes} \
	ES_RECOVER_EXPECTED_NODES=${es_recover_expected_nodes} \
	ES_RECOVER_AFTER_TIME=${es_recover_after_time} \
	)

es_ops_params=$(join , \
	ES_CLUSTER_NAME=es-ops \
	ES_INSTANCE_RAM=${es_ops_instance_ram} \
	ES_NODE_QUORUM=${es_ops_node_quorum} \
	ES_RECOVER_AFTER_NODES=${es_ops_recover_after_nodes} \
	ES_RECOVER_EXPECTED_NODES=${es_ops_recover_expected_nodes} \
	ES_RECOVER_AFTER_TIME=${es_ops_recover_after_time} \
	)

oc process -f templates/es.yaml -v "${es_params}" | oc create -f -
es_host=logging-es.${project}.svc.cluster.local
es_ops_host=${es_host}
oc process -f templates/kibana.yaml -v "OAP_PUBLIC_MASTER_URL=${public_master_url}" | oc create -f -
if [ "${ENABLE_OPS_CLUSTER}" == true ]; then
	oc process -f templates/es.yaml -v "${es_ops_params}" | oc create -f -
	es_ops_host=logging-es-ops.${project}.svc.cluster.local
	oc process -f templates/kibana.yaml -v "OAP_PUBLIC_MASTER_URL=${public_master_url},KIBANA_DEPLOY_NAME=kibana-ops" | oc create -f -
fi
oc process -f templates/fluentd.yaml -v "ES_HOST=${es_host},OPS_HOST=${es_ops_host}"| oc create -f -

if [ "${KEEP_SUPPORT}" != true ]; then
	oc delete template --selector logging-infra=support
	oc process -f templates/support.yaml -v "OAUTH_SECRET=$(cat $dir/oauth-secret),KIBANA_HOSTNAME=${hostname},KIBANA_OPS_HOSTNAME=${ops_hostname},IMAGE_PREFIX=${image_prefix},IMAGE_VERSION=${image_version}" | oc create -f -
	oc process -f templates/support-pre.yaml | oc create -f -
fi

echo "(Re-)Creating deployed objects"
if [ "${KEEP_SUPPORT}" != true ]; then
	oc delete sa,service --selector logging-infra=support
	oc process logging-support-pre-template | oc create -f -
fi

oc delete dc,rc,pod --selector logging-infra=kibana
oc delete dc,rc,pod --selector logging-infra=fluentd
oc delete dc,rc,pod --selector logging-infra=elasticsearch
for ((n=0;n<${es_cluster_size};n++)); do
	oc process logging-es-template | oc create -f -
done
oc process logging-fluentd-template | oc create -f -
oc process logging-kibana-template | oc create -f -
if [ "${ENABLE_OPS_CLUSTER}" == true ]; then
	for ((n=0;n<${es_ops_cluster_size};n++)); do
		oc process logging-es-ops-template | oc create -f -
	done
	oc process logging-kibana-ops-template | oc create -f -
fi


set +x
echo 'Success!'
saf="system:serviceaccount:${project}:aggregated-logging-fluentd"
support_section=''
if [ "${KEEP_SUPPORT}" != true ]; then
	support_section="
If you are replacing a previous deployment, delete the previous objects:
    oc delete route,is,oauthclient --selector logging-infra=support

Create the supporting definitions:
    oc process logging-support-template | oc create -f -

Enable fluentd service account - edit SCC with the following
    oc edit scc/privileged

Add one line as the user at the end:
- $saf

Give the account access to read pod metadata:
    openshift admin policy add-cluster-role-to-user cluster-reader $saf
"
fi
ops_cluster_section=""
if [ "${ENABLE_OPS_CLUSTER}" == true ]; then
	ops_cluster_section="
Operations logs:
----------------
You chose to split ops logs to their own ops cluster, which includes an
ElasticSearch cluster and its own deployment of Kibana. The deployments
are set apart by '-ops' in the name. The comments above about configuring
ES and scaling Kibana apply equally to the ops cluster.
"
fi

cat <<EOF

=================================

The deployer has created secrets, service accounts, templates, and
component deployments required for logging. You now have a few steps to
run as cluster-admin. Consult the deployer docs for more detail.
${support_section}
ElasticSearch:
--------------
Clustered instances have been created as individual deployments.

    oc get dc --selector logging-infra=elasticsearch

Your deployments will likely need to specify persistent storage volumes
and node selectors. It's best to do this before spinning up fluentd.
To attach persistent storage, you can modify each deployment through
'oc volume'.

Fluentd:
--------------
Fluentd is deployed with no replicas. Scale it to the number of nodes:

    oc scale dc/logging-fluentd --replicas=3
    oc scale rc/logging-fluentd-1 --replicas=3

Kibana:
--------------
You may scale the Kibana deployment for redundancy:

    oc scale dc/logging-kibana --replicas=2
    oc scale rc/logging-kibana-1 --replicas=2
${ops_cluster_section}
EOF

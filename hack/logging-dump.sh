#!/usr/bin/env bash
#
# Copyright 2017 Red Hat, Inc. and/or its affiliates
# and other contributors as indicated by the @author tags.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
if (( ${BASH_VERSION%%.*} < 4 ));
then
  echo "You need bash version higher than 4 to run this script."
  exit 1
fi

set -euo pipefail

declare -a components=()

while (($#))
do
case $1 in
    kibana|collector|curator|elasticsearch|project_info|elasticsearch-operator|cluster-logging-operator|install_info)
      components+=($1)
      ;;
    --outdir=*)
      target=${1#*=}
      ;;
    *)
      echo Ignoring unknown argument $1
      ;;
  esac
  shift
done

if [[ ${#components[@]} -eq 0 ]]
then
    components=( "kibana" "collector" "curator" "elasticsearch" "project_info" "elasticsearch-operator" "cluster-logging-operator" )
fi

NAMESPACE=openshift-logging

DATE=`date +%Y%m%d_%H%M%S`
target=${target:-"logging-$DATE"}
logs_folder="$target/logs"
es_folder="$target/elasticsearch"
collector_folder="$target/collector"
kibana_folder="$target/kibana"
curator_folder="$target/curator"
project_folder="$target/project"
eo_folder="$target/eo"
clo_folder="$target/clo"
install_folder="$target/install"

dump_resource_items() {
  local type=$1
  local ns=${2:-$NAMESPACE}
  mkdir $project_folder/$type
  for resource in `oc -n $ns get $type -o jsonpath='{.items[*].metadata.name}'`
  do
    oc get $type $resource -o yaml > $project_folder/$type/$resource
  done
}

dump_persistent_volumes() {
  local expected_pv_size=$(oc get persistentvolumeclaims --no-headers | wc -l)
  local pv_size=0
  mkdir $project_folder/persistentvolumes
  echo -- Extracting logging-es persistentvolumes ...
  for pv in `oc get persistentvolumes -o 'go-template={{range $pv := .items}}{{if $pv.spec.claimRef}}{{if eq $pv.spec.claimRef.namespace "'${NAMESPACE}'"}}{{$pv.metadata.name}}{{"\n"}}{{end}}{{end}}{{end}}'`
  do
    echo $pv
    oc get persistentvolumes $pv -o yaml > $project_folder/persistentvolumes/$pv
    pv_size=$((pv_size + 1))
  done
  if [ $pv_size != $expected_pv_size ]
  then
    echo -- Extracting unbound persistentvolumes ...
    for pv in `oc get persistentvolumes -o jsonpath='{.items[?(@.status.phase != "Bound")].metadata.name}'`
    do
      oc get persistentvolumes $pv -o yaml > $project_folder/persistentvolumes/$pv
    done
  fi
}

check_project_info() {
  mkdir $project_folder
  echo Getting general objects
  echo -- Nodes Description
  oc describe nodes > $project_folder/nodes
  echo -- Project Description
  oc get namespace ${NAMESPACE} -o yaml > $project_folder/logging-project
  echo -- Events
  oc get events --sort-by='.lastTimestamp' > $project_folder/events
  # Don't get the secrets content for security reasons
  echo -- Secrets
  oc describe secrets > $project_folder/secrets

  resource_types=(deployments daemonsets configmaps services routes serviceaccounts persistentvolumeclaims pods cronjobs)
  for resource_type in ${resource_types[@]}
  do
    echo -- Extracting $resource_type ...
    dump_resource_items $resource_type
  done
  dump_persistent_volumes
}

get_env() {
  local pod=$1
  local env_file=$2/$pod
  local ns=${3:-$NAMESPACE}
  local pattern=${4:-"Dockerfile-*logging*"}
  echo ---- Env for $pod
  containers=$(oc -n $ns get po $pod -o jsonpath='{.spec.containers[*].name}')
  for container in $containers
  do
    dockerfile=$(oc -n $ns exec $pod -c $container -- find /root/buildinfo -name $pattern || :)
    if [ -n "$dockerfile" ]
    then
      echo Dockerfile info: $dockerfile > $env_file
      oc -n $ns exec $pod -c $container -- grep -o "\"build-date\"=\"[^[:blank:]]*\"" $dockerfile >> $env_file || echo ---- Unable to get build date
    fi
    echo -- Environment Variables >> $env_file
    oc -n $ns exec $pod -c $container -- env | sort >> $env_file
  done
}

get_pod_logs() {
  local pod=$1
  local logs_folder=$2/logs
  local ns=${3:-$NAMESPACE}
  echo ---- Logs for POD $1
  if [ ! -d "$logs_folder" ]
  then
    mkdir $logs_folder
  fi
  local containers=$(oc -n $ns get po $pod -o jsonpath='{.spec.containers[*].name}')
  for container in $containers
  do
    echo ------ container: $container
    oc -n $ns logs $pod -c $container | nice xz > $logs_folder/$pod-$container.log.xz || oc logs $pod | nice xz > $logs_folder/$pod.log.xz || echo ---- Unable to get logs from pod $pod and container $container
  done

  if [ "$collector_folder" == "$2" ]	
  then	
    collector=fluentd
    oc exec $1 -c $collector -- logs | nice xz >> $logs_folder/$pod.log.xz
  fi
}

check_collector_connectivity() {
  local pod=$1
  echo --Connectivity between $pod and elasticsearch >> $collector_folder/$pod
  es_host=$(oc get pod $pod  -o jsonpath='{.spec.containers[0].env[?(@.name=="ES_HOST")].value}')
  es_port=$(oc get pod $pod  -o jsonpath='{.spec.containers[0].env[?(@.name=="ES_PORT")].value}')
  collector=fluent
  container=fluentd
  echo "  with ca" >> $collector_folder/$pod
  oc exec $pod -c $container -- curl -ILvs --key /etc/$collector/keys/key --cert /etc/$collector/keys/cert --cacert /etc/$collector/keys/ca -XGET https://$es_host:$es_port &>> $collector_folder/$pod
  echo "  without ca" >> $collector_folder/$pod
  oc exec $pod -c $container -- curl -ILkvs --key /etc/$collector/keys/key --cert /etc/$collector/keys/cert -XGET https://$es_host:$es_port &>> $collector_folder/$pod
}

check_collector_persistence() {
  local pod=$1
  echo --Persistence stats for pod $pod >> $collector_folder/$pod
  collector=fluentd
  fbstoragePath=$(oc get daemonset $collector -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[?(@.name=="filebufferstorage")].mountPath}')
  if [ -z "$fbstoragePath" ] ; then
    echo No filebuffer storage defined >>  $collector_folder/$pod
  else
    oc exec $pod -c $collector -- df -h $fbstoragePath >> $collector_folder/$pod
    oc exec $pod -c $collector -- ls -lr $fbstoragePath >> $collector_folder/$pod
  fi
}

check_collector() {
  echo -- Checking Collector health
  pods="$(oc get pods -l logging-infra=fluentd -o jsonpath={.items[*].metadata.name})"
  mkdir $collector_folder
  for pod in $pods
  do
    echo ---- Collector pod: $pod
    get_env $pod $collector_folder
    get_pod_logs $pod $collector_folder
    check_collector_connectivity $pod
    check_collector_persistence $pod
  done
}

check_cluster-logging-operator() {
  echo "Checking cluster-logging-operator"
  mkdir $clo_folder
  namespace="${NAMESPACE}"
  pods=$(oc -n $namespace get pods -l name=cluster-logging-operator -o jsonpath={.items[*].metadata.name})
  for pod in $pods
  do
    get_env $pod $clo_folder $namespace "Dockerfile-*operator*"
    get_pod_logs $pod $clo_folder $namespace
  done
  oc -n $namespace get deployment cluster-logging-operator -o yaml > $clo_folder/deployment
  csv_name="$(oc -n $namespace get csv -o name | grep 'cluster-logging-operator')"
  oc -n $namespace get "${csv_name}" -o yaml > "${clo_folder}/csv"
  oc -n $namespace get clusterlogging instance -o yaml > "${clo_folder}/cr"
  oc -n $namespace get logforwarding instance -o yaml > "${clo_folder}/logforwarding_cr" ||:
  oc -n $namespace get clusterlogforwarder instance -o yaml > "${clo_folder}/clusterlogforwarder_cr" ||:
}

check_elasticsearch-operator() {
  echo "Checking elasticsearch-operator"
  mkdir $eo_folder
  namespace=openshift-operators-redhat
  pods=$(oc -n $namespace get pods -l name=elasticsearch-operator -o jsonpath={.items[*].metadata.name})
  for pod in $pods
  do
    get_env $pod $eo_folder $namespace "Dockerfile-*operator*"
    get_pod_logs $pod $eo_folder $namespace
  done
  oc -n $namespace get deployment elasticsearch-operator -o yaml > $eo_folder/deployment
  csv_name="$(oc -n $namespace get csv -o name | grep 'elasticsearch-operator')"
  oc -n $namespace get "${csv_name}" -o yaml > "${eo_folder}/csv"
}

check_curator_connectivity() {
  local cron=$1
  echo --Connectivity between $cron and elasticsearch >> $curator_folder/$pod
  es_host=$(oc get cronjob $cron  -o jsonpath='{.spec.containers[0].env[?(@.name=="ES_HOST")].value}')
  es_port=$(oc get cronjob $cron  -o jsonpath='{.spec.containers[0].env[?(@.name=="ES_PORT")].value}')
  echo "  with ca" >> $curator_folder/$pod
  oc debug cronjob/$cron -- curl -ILvs --key /etc/curator/keys/key --cert /etc/curator/keys/cert --cacert /etc/curator/keys/ca -XGET https://$es_host:$es_port &>> $curator_folder/$pod
  echo "  without ca" >> $curator_folder/$pod
  oc debug cronjob/$cron -- curl -ILkvs --key /etc/curator/keys/key --cert /etc/curator/keys/cert -XGET https://$es_host:$es_port &>> $curator_folder/$pod
}

check_curator() {
  echo -- Checking Curator health
  local curator_pods=$(oc get pods -l logging-infra=curator -o jsonpath={.items[*].metadata.name})
  mkdir $curator_folder
  for pod in $curator_pods
  do
    echo ---- Curator pod: $pod
    get_env $pod $curator_folder
    get_pod_logs $pod $curator_folder
  done
  check_curator_connectivity curator
}

get_kibana_cr() {
  oc get -n ${NAMESPACE} kibana kibana -o yaml > $kibana_folder>cr
}

check_kibana_connectivity() {
  pod=$1
  echo ---- Connectivity between $pod and elasticsearch >> $kibana_folder/$pod
  es_url=$(oc get pod $pod  -o jsonpath='{.spec.containers[?(@.name=="kibana")].env[?(@.name=="ELASTICSEARCH_URL")].value}')
  echo "  with ca" >> $kibana_folder/$pod
  oc exec $pod -c kibana -- curl -ILvs --key /etc/kibana/keys/key --cert /etc/kibana/keys/cert --cacert /etc/kibana/keys/ca -XGET $es_url &>> $kibana_folder/$pod
  echo "  without ca" >> $kibana_folder/$pod
  oc exec $pod -c kibana -- curl -ILkvs --key /etc/kibana/keys/key --cert /etc/kibana/keys/cert -XGET $es_url &>> $kibana_folder/$pod
}

check_kibana() {
  echo -- Checking Kibana health
  kibana_pods=$(oc get pods -l logging-infra=kibana -o jsonpath={.items[*].metadata.name})
  mkdir $kibana_folder
  for pod in $kibana_pods
  do
    echo ---- Kibana pod: $pod
    get_env $pod $kibana_folder
    get_pod_logs $pod $kibana_folder
    check_kibana_connectivity $pod
    get_kibana_cr
  done
}

get_elasticsearch_cr() {
  oc get -n ${NAMESPACE} elasticsearch elasticsearch -o yaml > $es_folder>cr
}

get_elasticsearch_status() {
  local comp=$1
  local pod=${2:-""}
  if [ -z "$pod" ] ; then
      echo "Skipping elasticsearch status because no pod was found for $1"
      return
  fi
  local cluster_folder=$es_folder/cluster-$comp
  mkdir $cluster_folder
  curl_es='curl -s --max-time 5 --key /etc/elasticsearch/secret/admin-key --cert /etc/elasticsearch/secret/admin-cert --cacert /etc/elasticsearch/secret/admin-ca https://localhost:9200'
  local cat_items=(health nodes aliases thread_pool)
  for cat_item in ${cat_items[@]}
  do
    oc exec -c elasticsearch $pod -- $curl_es/_cat/$cat_item?v &> $cluster_folder/$cat_item
  done
  oc exec -c elasticsearch $pod -- $curl_es/_cat/indices?v\&bytes=m &> $cluster_folder/indices
  oc exec -c elasticsearch $pod -- $curl_es/_search?sort=@timestamp:desc\&pretty > $cluster_folder/latest_documents.json
  oc exec -c elasticsearch $pod -- $curl_es/_nodes/stats?pretty > $cluster_folder/nodes_stats.json
  local health=$(oc exec -c elasticsearch $pod -- $curl_es/_cat/health?h=status)
  if [ -z "$health" ]
  then
    echo "Unable to get health from $1"
  elif [ $health != "green" ]
  then
    echo Gathering additional cluster information Cluster status is $health
    cat_items=(recovery shards pending_tasks)
    for cat_item in ${cat_items[@]}
    do
      oc exec -c elasticsearch $pod -- $curl_es/_cat/$cat_item?v &> $cluster_folder/$cat_item
    done
    oc exec -c elasticsearch $pod -- $curl_es/_cat/shards?h=index,shard,prirep,state,unassigned.reason,unassigned.description | grep UNASSIGNED &> $cluster_folder/unassigned_shards
  fi
}

get_es_logs() {
  local pod=$1
  local logs_folder=$2/logs
  echo -- POD $1 Elasticsearch Logs
  if [ ! -d "$logs_folder" ]
  then
    mkdir $logs_folder
  fi
  path=/elasticsearch/persistent/elasticsearch/logs
  exists=$( oc exec $pod -c elasticsearch -- ls ${path} 2> /dev/null ) || :
  if [ -z "$exists" ]; then
    path=/elasticsearch/elasticsearch/logs
  fi
  exists=$( oc exec $pod -c elasticsearch -- ls ${path} 2> /dev/null ) || :
  if [ -z "$exists" ]; then
    echo ---- Unable to get ES logs from pod $pod
  else
    oc rsync -c elasticsearch -q $pod:$path $logs_folder 2> /dev/null || echo ---- Unable to get ES logs from pod $pod
    mv -f $logs_folder/logs $logs_folder/$pod
    nice xz $logs_folder/$pod/*
  fi
}

list_es_storage() {
  local pod=$1
  local mountPath=$(oc get pod $pod -o jsonpath='{.spec.containers[0].volumeMounts[?(@.name=="elasticsearch-storage")].mountPath}')
  echo -- Persistence files -- >> $es_folder/$pod
  oc exec -c elasticsearch $pod -- ls -lR $mountPath >> $es_folder/$pod
}

check_elasticsearch() {
  echo Checking Elasticsearch health
  echo -- Checking Elasticsearch health
  local es_pods=$(oc get pods -l component=elasticsearch -o jsonpath={.items[*].metadata.name})
  mkdir $es_folder
  for pod in $es_pods
  do
    echo ---- Elasticsearch pod: $pod
    get_env $pod $es_folder
    get_pod_logs $pod $es_folder
    get_es_logs $pod $es_folder
    list_es_storage $pod
    get_elasticsearch_cr
  done

  local anypod=""
  for comp in "elasticsearch"
  do
    echo -- Getting Elasticsearch cluster info from logging-${comp} pod
    anypod=$(oc get po --selector="component=${comp}" --no-headers | grep Running | awk '{print$1}' | tail -1 || :)
    get_elasticsearch_status ${comp} ${anypod}
  done
}

check_install_info() {
  echo Gathering install info
  mkdir $install_folder

  echo Getting install objects
  echo -- Subscription
  oc get -n ${NAMESPACE} subscription -o yaml > "$install_folder>subscription"
  echo -- Install Plan
  oc get -n ${NAMESPACE} installplan -o yaml > "$install_folder>install_plan"
  echo -- Catalog Operator logs
  oc logs -n openshift-operator-lifecycle-manager -l app=catalog-operator > "$install_folder>co_logs"
  echo -- OLM Operator logs
  oc logs -n openshift-operator-lifecycle-manager -l app=olm-operator > "$install_folder>olmo_logs"
}

oc project $NAMESPACE
echo Retrieving results to $target

if [ ! -d ${target} ]
then
  mkdir -p $target
fi

for comp in "${components[@]}"
do
    eval "check_${comp}" || echo Unrecognized function "'check_${comp}'" to check component: "'${comp}'"
done

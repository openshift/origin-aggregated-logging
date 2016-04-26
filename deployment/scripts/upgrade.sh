#! /bin/bash

set -ex

TIMES=300

fluentd_nodes=""
fluentd_nodeselector="logging-infra-fluentd=true"

function getDeploymentVersion() {
  #base this on what isn't installed
  local version=0

  # Check for the admin cert
  if [[ -n "$(oc get secrets -o jsonpath='{.items[?(@.data.admin-cert)].metadata.name}')" ]]; then
    version=1
  else
    echo "$version"
    return
  fi

  # Check for fluentd daemonset and curator
  if [[ -n "$(oc get daemonset -o jsonpath='{.items[?(@.metadata.name=="logging-fluentd")].metadata.name}')" && -n "$(oc get dc -l logging-infra=curator -o jsonpath='{.items[*].metadata.name}')" ]]; then
    version=2
  else
    echo "$version"
    return
  fi

  echo "$version"
}

function waitForStop() {

  local pod_name=$1
  local label=$2

  STOPPED=0
  for i in $(seq 1 $TIMES); do
    if [[ -n $(oc get pods -l $label -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}') ]]; then
      sleep 1
    else
      STOPPED=1
      break
    fi
  done

  if [[ $STOPPED -eq 0 ]]; then
    echo "$pod_name not stopped within $TIMES seconds"
    return 1
  else
    return 0
  fi
}

function waitForStart() {

  local pod_name=$1
  #local label=$2

  STARTED=0
  for i in $(seq 1 $TIMES); do
    if [[ "Running" == "$(oc get pod $pod_name -o jsonpath='{.status.phase}')" ]]; then
      sleep 1
    else
      STARTED=1
      break
    fi
  done

  if [[ $STARTED -eq 0 ]]; then
    echo "$pod_name not started within $TIMES seconds"
    return 1
  else
    return 0
  fi
}

# This lets us wait until the pod has been scheduled before we try to grab its name
function getPodName() {

  local dc=$1

  FOUND=0
  for i in $(seq 1 $TIMES); do
    local pod=$(oc get pod -l deploymentconfig=$dc -o jsonpath="{.items[?(.metadata.labels.deploymentconfig==\"$dc\")].metadata.name}")
    if [[ -z "$pod" ]]; then
      sleep 1
    else
      FOUND=1
      break
    fi
  done

  if [[ $FOUND -eq 0 ]]; then
    return 1
  else
    echo "$pod"
  fi
}

function checkESStarted() {

  local pod=$1

  FOUND=0
  for i in $(seq 1 $TIMES); do
    local cluster_service=$(oc logs $1 | grep "\[cluster\.service[[:space:]]*\]")
    if [[ -z "$cluster_service" ]]; then
      sleep 1
    else
      FOUND=1
      break
    fi
  done
  if [[ $FOUND -eq 0 ]]; then
    echo "Unable to find log message from cluster.service within $TIMES seconds"
    return 1
  fi

  # If we detect a master, we won't recover indices
  #  check for output from "[cluster.service " with "] detected_master ["
# OR
  # We're the master if we see this
  #  check for output from "[cluster.service " with "] new_master ["
  local master=$(echo $cluster_service | grep "new_master")
  local non_master=$(echo $cluster_service | grep "detected_master")

  # Check that we started
  #  check for output from "[node " with "] started"
  FOUND=0
  for i in $(seq 1 $TIMES); do
    if [[ -z $(oc logs $1 | grep "\[node[[:space:]]*\][[:space:]]*\[.*\][[:space:]]*started") ]]; then
      sleep 1
    else
      FOUND=1
      break
    fi
  done
  if [[ $FOUND -eq 0 ]]; then
    echo "Unable to find log message from node that ES started within $TIMES seconds"
    return 1
  fi

  # Check that it recovered its indices after starting if we're a master
  #  check for output from "[gateway" with "] recovered[:num:] indices into cluster state"
  if [[ -n "$master" ]]; then
    FOUND=0
    for i in $(seq 1 $TIMES); do
      # node names are as complicated as "Lilith, the Daughter of Dracula" so we'll just match .*
      if [[ -z $(oc logs $1 | grep "\[gateway[[:space:]]*\][[:space:]]*\[.*\][[:space:]]*recovered[[:space:]]*\[[[:digit:]]*\][[:space:]]*indices into cluster_state") ]]; then
        sleep 1
      else
        FOUND=1
        break
      fi
    done
    if [[ $FOUND -eq 0 ]]; then
      echo "Unable to find log message from gateway that ES recovered its indices within $TIMES seconds"
      return 1
    fi
  else
    # Does this check make sense to happen after we check if the node started?
    # TODO: verify the order that a non-master node does its checks...
    if [[ -z "$non_master" ]]; then
      echo "Node isn't master and was unable to detect master"
      return 1
    fi
  fi
}

function checkKibanaStarted() {

  local pod=$1

  #TODO: this looping logic can probably be refactored into a function
  FOUND=0
  for i in $(seq 1 $TIMES); do
    if [[ -z $(oc logs $1 -c kibana | grep "Listening on 0.0.0.0:5601") ]]; then
      sleep 1
    else
      FOUND=1
      break
    fi
  done
  if [[ $FOUND -eq 0 ]]; then
    echo "Kibana was not able to start up within $TIMES seconds"
    return 0
  fi
}

function scaleDown() {

  # check for a fluentd dc, if there isn't one it was either deleted or using a daemonset
  local fluentd_dc=(`oc get dc -l logging-infra=fluentd -o jsonpath='{.items[*].metadata.name}'`)

  # find what nodes fluentd is currently deployed to
  fluentd_nodes=(`oc get pods -l component=fluentd -o jsonpath='{.items[*].spec.nodeName}'`)
  if [[ -z "$fluentd_dc" ]]; then
    # oc get daemonset -l logging-infra=fluentd -o jsonpath='{.items[*].metadata.name}'
    local selector=$(oc get daemonset -l logging-infra=fluentd -o jsonpath='{.items[*].spec.template.spec.nodeSelector}')
    if [[ -n "$selector" ]]; then
      fluentd_nodeselector=$(echo ${selector:4:-1} | sed 's/:/=/g')

      oc delete daemonset logging-fluentd
    fi
  else
    # we are using a deployment config, scale down here
    for dc in "${fluentd_dc[@]}"; do
      oc scale --replicas=0 dc $dc
    done
  fi

  for pod in $(oc get pods -l component=fluentd -o jsonpath='{.items[*].metadata.name}'); do
    waitForStop $pod "component=fluentd"
  done

  # probably can refactor this out into a function...
  local kibana_dc=(`oc get dc -l logging-infra=kibana -o jsonpath='{.items[*].metadata.name}'`)
  for dc in "${kibana_dc[@]}"; do
    oc scale --replicas=0 dc $dc
  done
  for pod in $(oc get pods -l component=kibana -o jsonpath='{.items[*].metadata.name}'); do
    waitForStop $pod "component=kibana"
  done

  local elasticsearch_dc=(`oc get dc -l logging-infra=elasticsearch -o jsonpath='{.items[*].metadata.name}'`)
  for dc in "${elasticsearch_dc[@]}"; do
    oc scale --replicas=0 dc $dc
  done
  for pod in $(oc get pods -l component=es -o jsonpath='{.items[*].metadata.name}'); do
    waitForStop $pod "component=es"
  done
}

function scaleUp() {

  # scale up ES slowly -- we want to wait for each instance to recover its indices first
  local elasticsearch_dc=(`oc get dc -l logging-infra=elasticsearch -o jsonpath='{.items[*].metadata.name}'`)
  for dc in "${elasticsearch_dc[@]}"; do
    oc scale --replicas=1 dc $dc

    pod=$(getPodName $dc)
    waitForStart $pod

    # the first one we start gets to be the master
    checkESStarted $pod
  done

  local kibana_dc=(`oc get dc -l logging-infra=kibana -o jsonpath='{.items[*].metadata.name}'`)
  for dc in "${kibana_dc[@]}"; do
    oc scale --replicas=1 dc $dc

    pod=$(getPodName $dc)
    waitForStart $pod
    checkKibanaStarted $pod
  done
}

function updateImages() {

  # create any missing imagestreams and then update them all
  oc new-app logging-imagestream-template || : # these may fail if created independently; that's ok

  # TODO: update these to fail if we can't import?
  oc import-image logging-elasticsearch || :
  oc import-image logging-fluentd || :
  oc import-image logging-kibana || :
  oc import-image logging-curator || :
}

# we can just specify to regenerate our certs
function add_curator() {

  echo "Adding curator..."
  # this may fail otherwise if there was only a partial upgrade previously
  oc delete dc,rc,template --selector logging-infra=curator || :

  generate_curator_template
  generate_curator
}

function fluentd_daemonset() {
  echo "Updating Fluentd to use Daemonset..."

  # this may fail otherwise if there was only a partial upgrade previously
  oc delete dc,rc,template,daemonset --selector logging-infra=fluentd || :

  generate_fluentd_template
  generate_fluentd
}

function upgrade_notify() {
  set +x
  echo "Upgrade complete!"
  cat <<EOF

=================================

The deployer has created additional secrets, templates, and component deployments
as part of the upgrade process. You may now have a few more steps to run manually.
Consult the deployer docs for more detail.

Fluentd:
--------------
Fluentd is deployed to nodes via a DaemonSet. If this is new for your deployment:
as a cluster admin label the nodes you'd like to deploy it to:
    oc label node/<node-name> ${fluentd_nodeselector}

To label all nodes at once:
    oc label nodes --all ${fluentd_nodeselector}

Note: if your previous deployment used a DaemonSet for Fluentd, there should be
no additional actions to deploy your pods -- the deployer did not unlabel any nodes.
EOF
}

function regenerate_secrets_and_support_objects() {
  oc process logging-support-template | oc delete -f - || :
  oc delete imagestream,service,route,template --selector logging-infra=support
  # note: dev builds aren't labeled and won't be deleted. if you need to preserve imagestreams, you can just remove the label.
  # note: no automatic deletion of persistentvolumeclaim; didn't seem wise

  generate_secrets
  generate_support_objects
}

function upgrade_logging() {

  installedVersion=$(getDeploymentVersion)
  local migrate=

  # VERSIONS
  # 0 -- just EFK
  # 1 -- admin cert
  # 2 -- curator & daemonset

  # start with installed version and go until we're at $LOGGING_VERSION
  if [[ $installedVersion -eq $LOGGING_VERSION ]]; then
    echo "Already at latest version. No upgrade will be done at this time."
  else
    scaleDown
    initialize_install_vars

    # Does it make sense to just do this always?
    regenerate_secrets_and_support_objects
    # This needs to happen before the uuid_migrate....
    updateImages

    for version in $(seq $installedVersion $LOGGING_VERSION); do
      case "${version}" in
        0)
          migrate=true
          ;;
        1)
          # Add Curator
          add_curator
          # Add Fluentd Daemonset
          fluentd_daemonset
          ;;
        $LOGGING_VERSION)
          scaleUp

          if [[ -n "$migrate" ]]; then
            uuid_migrate
          fi

          upgrade_notify
          ;;
      esac
    done
  fi
}

#! /bin/bash

set -ex

TIMES=300
fluentd_nodeselector="logging-infra-fluentd=true"

patchPIDs=()

function getDeploymentVersion() {
  #base this on what isn't installed

  # Check for the admin cert
  if [[ -z "$(oc get secrets -o jsonpath='{.items[?(@.data.admin-cert)].metadata.name}')" ]]; then
    echo 0
    return
  fi

  # Check for fluentd daemonset and curator
  if [[ -z "$(oc get daemonset -l logging-infra=fluentd -o jsonpath='{.items[*].metadata.name}')" || -z "$(oc get dc -l logging-infra=curator -o jsonpath='{.items[*].metadata.name}')" ]]; then
    echo 1
    return
  fi

  # Check for DC triggers
  if [[ -n "$(oc get dc -l logging-infra -o jsonpath='{.items[?(@.spec.triggers[*].type)].metadata.name}')" ]]; then
    echo 2
    return
  fi

  echo "$LOGGING_VERSION"
}

function waitFor() {

  local statement=$1
  for (( i=1; i<=$TIMES; i++ )); do
    eval "$statement" && return 0
    sleep 1
  done
  return 1
}

function waitForValue() {

  local value=$1

  if waitFor "[[ -n \$($value) ]]"; then
    eval $value
    return 0
  fi
  echo "$value not found within $TIMES seconds"
  return 1
}

function waitForStop() {

  local pod_name=$1
  local label=$2

  waitFor "[[ -z \$(oc get pods -l $label -o jsonpath='{.items[?(@.status.phase==\"Running\")].metadata.name}') ]]" && return 0
  echo "$pod_name not stopped within $TIMES seconds"
  return 1
}

function waitForStart() {

  local pod_name=$1

  waitFor "[[ \"Running\" == \"\$(oc get pod $pod_name -o jsonpath='{.status.phase}')\" ]]" && return 0
  echo "$pod_name not started within $TIMES seconds"
  return 1
}

# This lets us wait until the pod has been scheduled before we try to grab its name
function getPodName() {

  local dc=$1
  local pod

  pod=$(waitForValue "oc get pod -l deploymentconfig=$dc -o jsonpath='{.items[?(.metadata.labels.deploymentconfig==\"$dc\")].metadata.name}'") || return 1
  echo "$pod"
}

function checkESStarted() {

  local pod=$1
  local cluster_service

  if ! cluster_service=$(waitForValue "oc logs $pod | grep '\[cluster\.service[[:space:]]*\]'"); then
    echo "Unable to find log message from cluster.service within $TIMES seconds"
    return 1
  fi

  # If this instance detects a different master, it won't recover its own indices
  #  check for output from "[cluster.service " with "] detected_master ["
  local non_master=$(echo $cluster_service | grep "detected_master")
# OR
  # instance is the master if logs have this:
  #  check for output from "[cluster.service " with "] new_master ["
  local master=$(echo $cluster_service | grep "new_master")

  # Check that instance started.
  #  check for output from "[node " with "] started"

  if ! waitFor "[[ -n \"\$(oc logs $pod | grep '\[node[[:space:]]*\][[:space:]]*\[.*\][[:space:]]*started')\" ]]"; then
    echo "Unable to find log message from node that ES started within $TIMES seconds"
    return 1
  fi

  # Check that it recovered its indices after starting if a master
  #  check for output from "[gateway" with "] recovered[:num:] indices into cluster state"
  if [[ -n "$master" ]]; then
    if ! waitFor "[[ -n \"\$(oc logs $pod | grep '\[gateway[[:space:]]*\][[:space:]]*\[.*\][[:space:]]*recovered[[:space:]]*\[[[:digit:]]*\][[:space:]]*indices into cluster_state')\" ]]"; then
      echo "Unable to find log message from gateway that ES recovered its indices within $TIMES seconds"
      return 1
    fi
  else
    # if we aren't master we should be started by now and should have detected a master
    if [[ -z "$non_master" ]]; then
      echo "Node isn't master and was unable to detect master"
      return 1
    fi
  fi
}

function checkKibanaStarted() {

  local pod=$1

  if ! waitFor "[[ -n \$(oc logs $pod -c kibana | grep 'Listening on 0.0.0.0:5601') ]]"; then
    echo "Kibana was not able to start up within $TIMES seconds"
    return 1
  fi
}

# This function looks for the annotation "previousReplicas" and returns that value
# if it exists, otherwise it returns "1"
function getPreviousReplicas() {

  local dc=$1 previous
  if previous=$(oc get dc/${dc} -o jsonpath='{.metadata.annotations.previousReplicas}' 2>&1); then
    echo $previous
  else
    echo "1"
  fi
}

function scaleDownDCsAndWait() {

  local infra=$1
  local component=${2:-$infra}
  local ops=${3:-true}

  local dcs=$(oc get dc -l logging-infra=$infra -o jsonpath='{.items[*].metadata.name}')
  for dc in $dcs; do
    oc annotate dc/${dc} previousReplicas=$(oc get dc/${dc} -o jsonpath='{.spec.replicas}') --overwrite
    oc scale --replicas=0 dc $dc
  done

  for pod in $(oc get pods -l component=$component -o jsonpath='{.items[*].metadata.name}'); do
    waitForStop $pod "component=$component"
  done

  if [ "$ops" = true ]; then
    for pod in $(oc get pods -l component=${component}-ops -o jsonpath='{.items[*].metadata.name}'); do
      waitForStop $pod "component=${component}-ops"
    done
  fi
}

function scaleDown() {

  # check for a fluentd dc, if none either it was deleted or deployment already uses a daemonset
  local fluentd_dc=(`oc get dc -l logging-infra=fluentd -o jsonpath='{.items[*].metadata.name}'`)

  if [[ -z "$fluentd_dc" ]]; then
    local selector=$(oc get daemonset -l logging-infra=fluentd -o jsonpath='{.items[*].spec.template.spec.nodeSelector}')
    if [[ -n "$selector" ]]; then
      fluentd_nodeselector=$(echo ${selector:4:-1} | sed 's/:/=/g')

      oc delete daemonset logging-fluentd
    fi
  else
    # we are using a deployment config, scale down here
    # annotate in case we aren't upgrading, only stopping and starting
    for dc in "${fluentd_dc[@]}"; do
      oc annotate dc/${dc} previousReplicas=$(oc get dc/${dc} -o jsonpath='{.spec.replicas}') --overwrite
      oc scale --replicas=0 dc $dc
    done
  fi
  for pod in $(oc get pods -l component=fluentd -o jsonpath='{.items[*].metadata.name}'); do
    waitForStop $pod "component=fluentd"
  done

# Curator
  scaleDownDCsAndWait "curator"

# Kibana
  scaleDownDCsAndWait "kibana"

# Elasticsearch
  scaleDownDCsAndWait "elasticsearch" "es"
}

function scaleUpDCsAndCheck() {

  local component=$1
  local extraCheck=$2

  local dcs=$(oc get dc -l logging-infra=$component -o jsonpath='{.items[*].metadata.name}')

  # scale them all up first
  for dc in $dcs; do
    replicas=$(getPreviousReplicas "$dc")
    [[ $replicas -gt 0 ]] && oc scale --replicas=$replicas dc/$dc
  done
  # then check that they started up
  for dc in $dcs; do
    replicas=$(getPreviousReplicas "$dc")
    if [[ $replicas -gt 0 ]]; then
      # if we're still at 0 replicas after we scaled up...
      # possibly due to ttl failing on dc and annotation sync not being accurate; scale to 0 then scale back up
      [[ 0 -eq $(oc get dc/$dc -o jsonpath='{.spec.replicas}') ]] && oc scale --replicas=0 dc/$dc && oc scale --replicas=$replicas dc/$dc

      for pod in $(getPodName $dc); do
        waitForStart $pod

        if [[ -n $extraCheck ]]; then
          eval $extraCheck $pod
        fi
      done
    fi
  done
}

function scaleUp() {

# Elasticsearch
  scaleUpDCsAndCheck "elasticsearch" "checkESStarted"

# Curator
  scaleUpDCsAndCheck "curator"

# Kibana
  scaleUpDCsAndCheck "kibana" "checkKibanaStarted"

# Fluentd
  # check for fluentd DC first -- we may not have done an upgrade so we won't have a daemonset to create
  local fluentd_dc=(`oc get dc -l logging-infra=fluentd -o jsonpath='{.items[*].metadata.name}'`)

  if [[ -z "$fluentd_dc" ]]; then
    if [[ -z $(oc get daemonset -l logging-infra=fluentd -o jsonpath='{.items[*].metadata.name}') ]]; then
      # if the daemonset doesn't exist, recreate it here
      if [[ -z $(oc get template -l logging-infra=fluentd -o jsonpath='{.items[*].metadata.name}') ]]; then
        #  if the template doesn't exist, recreate it
        generate_fluentd_template
      fi

      generate_fluentd
    fi
  else
    # we are using a deployment config, scale up here
    # we don't need to make sure fluentd started up...?
    for dc in "${fluentd_dc[@]}"; do
      oc scale --replicas=$(getPreviousReplicas "$dc") dc $dc
    done
  fi
}

function getArrayIndex() {

  local object=$1
  local path=$2
  local name=$3
  local to_match=$4

  local length=$(oc get $object -o jsonpath="{$path[*].$name}" | xargs -n1 | wc -l)

  local matched_indices=()

  for index in $(seq 0 $((length - 1)) ); do
    if [[ "$to_match" == $(oc get $object -o jsonpath="{$path[$index].$name}") ]]; then
      matched_indices+=( $index)
    fi
  done

  if [[ -z "${matched_indices[@]}" ]]; then
    echo "-1"
  else
    echo "${matched_indices[@]}"
  fi
}

# This function will wait until the latestVersion changes
function waitForChange() {

  local currentVersion=$1
  local dc=$2

  waitFor "[[ $currentVersion -lt \$(oc get $dc -o jsonpath='{.status.latestVersion}') ]]" && return 0

  return 1
}

# This function will tell us if the proposed patches are different than the current values
function isValidChange() {

  local object=$1; shift

  for patch in $@; do
    path="$(echo $patch | cut -d"=" -f 1)"
    value="$(echo $patch | cut -d"=" -f 2)"
    result="$(oc get $object -o jsonpath="$path")"

    # we want to do a conversion of the image tag to the sha256 when checking images
    # if path contains "containers" then we're doing an image patch
    # the IS is between a "/" and ":" in value
    if [[ "$path" =~ "containers" ]]; then
      #we want to check if the tag or the sha256 match
      image=$(echo $value | sed "s,$IMAGE_PREFIX,,")

      is=$(echo $image | cut -d":" -f 1)
      tag=$(echo $image | cut -d":" -f 2)

      shaValue=$(echo $value | grep -o '^.*:')
      # drop last ":" and replace with "@"
      shaValue=$(echo ${shaValue:0:-1}@)
      shaValue+=$(oc get is $is -o jsonpath="{.status.tags[?(@.tag==\"$tag\")].items[0].image}")

      [[ "$result" != "$value" ]] && \
      [[ "$result" != "$shaValue" ]] && return 0
    else
      [[ "$result" != "$value" ]] && return 0
    fi
  done

  echo "Same values as intended patches for $object"
  return 1
}

function patchIfValid() {

  local object=$1; shift
  local isDC=false
  local currentVersion
  local actualPatch=()

  [[ -n $(echo $object | grep '^dc\/') ]] && isDC=true

  if [ $isDC = true ]; then
    currentVersion=$(oc get $object -o jsonpath='{.status.latestVersion}')
  fi

  if ! isValidChange "$object" "$@"; then
    return 0
  fi

  for patch in $@; do
    # delimeter is '='

    # we're changing the format of path from "{.status.tags[0].items[0].image}" to
    # "/status/tags/0/items/0/image"  so we can oc patch using --type json
    path=$(echo $patch | cut -d"=" -f 1 | sed 's/[\.[]/\//g ; s/[]}{]//g')
    value=$(echo $patch | cut -d"=" -f 2)

    actualPatch+=( '{"op":"replace","path":"'$path'","value":"'$value'"}')
  done

  if oc patch $object --type=json -p="[$(join , "${actualPatch[@]}")]"; then
    if [[ $isDC = true ]]; then
      oc deploy $object --latest
      waitForChange $currentVersion $object &
      patchPIDs+=( $!)
    fi

    return 0
  fi

  return 1
}

# this is to go through and update a template with the latest image version
function patchTemplateParameter() {
  local template=$1
  local index=$(getArrayIndex "template/$template" ".parameters" "name" "IMAGE_VERSION")

  if [[ $index -gt -1 ]]; then

    patchIfValid "template/$template" "{.parameters[$index].value}=$IMAGE_VERSION" && return 0

    echo "Did not patch template/$template successfully"
    return 1
  fi
}

# this is to go through and update a DC with the latest image versions
# patch image and update the imagechange tag
# wait for new .status.latestversion to be -gt previous one
function patchDCImage() {

  local dc=$1
  local image=$2
  local kibana=$3
  local version=$(oc get dc/$dc -o jsonpath='{.status.latestVersion}')
  local authProxy_patch

  if [ "$kibana" = true ]; then
    authProxy_patch="{.spec.template.spec.containers[1].image}=${IMAGE_PREFIX}logging-auth-proxy:${IMAGE_VERSION}"
  fi

  patchIfValid "dc/$dc" "{.spec.template.spec.containers[0].image}=${IMAGE_PREFIX}${image}:${IMAGE_VERSION} \
                         ${authProxy_patch}" && return 0

  echo "Did not patch dc/$dc successfully"
  return 1
}

# this is to go through and update the DCs and templates with the latest image versions
function patchImageVersion() {

  local label=$1
  local image=$2
  local is_kibana=${3:-false}
  local template_only=${4:-false}

  for template in $(oc get templates -l $label -o jsonpath='{.items[*].metadata.name}'); do
    patchTemplateParameter $template
  done
  if [ "$template_only" = false ]; then
    for dc in $(oc get dc -l $label -o jsonpath='{.items[*].metadata.name}'); do
      patchDCImage $dc $image $is_kibana
    done
  fi
}

function updateImages() {

  # this should only patch the template if it exists (in the case of dev builds)
  patchTemplateParameter "logging-imagestream-template"

  # patch all es
  patchImageVersion "logging-infra=elasticsearch" "logging-elasticsearch"

  # patch all Kibana
  patchImageVersion "logging-infra=kibana" "logging-kibana" true

  # patch all curator
  patchImageVersion "logging-infra=curator" "logging-curator"

  # patch fluentd -- or just recreate template?
  patchImageVersion "logging-infra=fluentd" "logging-fluentd" false true

  # wait for all the config changes we wait on to be pulled in
  wait ${patchPIDs[@]}
}

# we can just specify to regenerate our certs
function add_curator() {

  echo "Adding curator..."
  # this may fail otherwise if there was only a partial upgrade previously
  oc delete dc,rc,template --selector logging-infra=curator || :

  generate_curator_template
  generate_curator

  for dc in $(oc get dc -l logging-infra=curator -o name); do
    oc deploy $dc --latest
  done
}

function add_fluentd_daemonset() {
  echo "Updating Fluentd to use Daemonset..."

  # this may fail otherwise if there was only a partial upgrade previously
  oc delete dc,rc,template,daemonset --selector logging-infra=fluentd || :

  generate_fluentd_template
  generate_fluentd
}

function upgrade_notify() {
  set +x
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
  oc delete service,route,template --selector logging-infra=support
  # note: dev builds aren't labeled and won't be deleted. if you need to preserve imagestreams, you can just remove the label.
  # note: no automatic deletion of persistentvolumeclaim; didn't seem wise

  generate_secrets
  generate_support_objects
}

function remove_triggers_and_IS() {

  # This is getting only the names of DCs that still have a trigger defined
  # ?(@.spec.triggers[*].type) only matches on DC that have a value for 'type' under .spec.triggers[*]
  for dc in $(oc get dc -l logging-infra -o jsonpath='{.items[?(@.spec.triggers[*].type)].metadata.name}'); do
    oc patch dc/$dc -p='{"spec": { "triggers" : [] } }'
  done

  # since we no longer have triggers, we do not need to use image streams
  # removing generated, non-dev, image streams to avoid confusion
  oc delete is -l logging-infra=support
}

function upgrade_logging() {

  installedVersion=$(getDeploymentVersion)
  local migrate=

  # VERSIONS
  # 0 -- just EFK
  # 1 -- admin cert
  # 2 -- curator & daemonset
  # 3 -- no change triggers

  initialize_install_vars

  scaleDown
  updateImages

  # start with installed version and go until we're at $LOGGING_VERSION

  # this means that we don't have any infrastructure changes... we should still
  # scale down, update images (patch dc if needed), and scale back up
  if [[ $installedVersion -eq $LOGGING_VERSION ]]; then
    echo "No infrastructure changes required for Aggregated Logging."
  else
    regenerate_secrets_and_support_objects

    for version in $(seq $installedVersion $LOGGING_VERSION); do
      case "${version}" in
        0)
          migrate=true
          ;;
        1)
          # Add Curator
          add_curator
          # Add Fluentd Daemonset
          add_fluentd_daemonset
          ;;
        2)
          # Remove triggers
          remove_triggers_and_IS
          ;;
        $LOGGING_VERSION)
          echo "Infrastructure changes for Aggregated Logging complete..."
          ;;
      esac
    done
  fi

  scaleUp

  if [[ $installedVersion -ne $LOGGING_VERSION ]]; then
    if [[ -n "$migrate" ]]; then
      uuid_migrate
    fi

    upgrade_notify
  fi

  set +x
  echo "Upgrade complete!"
}

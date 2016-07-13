#!/bin/bash

if [ "$VERBOSE" = true ]; then
  set -ex
else
  set -e
fi

TIMES=300

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

function checkESStarted() {

  local pod=$1
  local cluster_service

  if ! cluster_service=$(waitForValue "oc logs $pod | grep '\[cluster\.service[[:space:]]*\]'"); then
    echo "Unable to find log message from cluster.service for pod $pod within $TIMES seconds"
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
    echo "Unable to find log message from node that ES pod $pod started within $TIMES seconds"
    return 1
  fi

  # Check that it recovered its indices after starting if a master
  #  check for output from "[gateway" with "] recovered[:num:] indices into cluster state"
  if [[ -n "$master" ]]; then
    if ! waitFor "[[ -n \"\$(oc logs $pod | grep '\[gateway[[:space:]]*\][[:space:]]*\[.*\][[:space:]]*recovered[[:space:]]*\[[[:digit:]]*\][[:space:]]*indices into cluster_state')\" ]]"; then
      echo "Unable to find log message from gateway that ES pod $pod recovered its indices within $TIMES seconds"
      return 1
    fi
  else
    # if we aren't master we should be started by now and should have detected a master
    if [[ -z "$non_master" ]]; then
      echo "For ES pod $pod - node isn't master and was unable to detect master"
      return 1
    fi
  fi
}

function checkKibanaStarted() {

  local pod=$1

  if ! waitFor "[[ -n \$(oc logs $pod -c kibana | grep 'Listening on 0.0.0.0:5601') ]]"; then
    echo "Kibana pod $pod was not able to start up within $TIMES seconds"
    return 1
  fi
}

# add one since fluentd will be deployed via a daemonset
# keeping as -2 + 1 for readibilty
ADDITIONAL_PODS=$((KIBANA_CLUSTER_SIZE + ES_CLUSTER_SIZE - 2 + 1))

EXIT_CODE=0

if [[ $# -ne 1 ]]; then
  # assuming not using OPS cluster
  CLUSTER="false"
else
  CLUSTER="$1"
  ADDITIONAL_PODS=$((ADDITIONAL_PODS + KIBANA_OPS_CLUSTER_SIZE + ES_OPS_CLUSTER_SIZE - 2))
fi

if [[ "$CLUSTER" == "true" ]]; then
  NEEDED_COMPONENTS=("logging-es-[a-ZA-Z0-9]+?0" "logging-kibana0" "logging-curator0" "logging-es-ops-[a-zA-Z0-9]+?0" "logging-kibana-ops0" "logging-curator-ops0")
else
  NEEDED_COMPONENTS=("logging-es-[a-zA-Z0-9]+?0" "logging-kibana0" "logging-curator0")
fi

TEST_DIVIDER="-------------------------------------------------------"
COMPONENTS_COUNT=${#NEEDED_COMPONENTS[@]}

echo "Checking component installation and if pods are running:"
echo $TEST_DIVIDER
# Check that we have DC

FOUND_DC=(`oc get dc -l logging-infra -o jsonpath='{.items[*].metadata.labels.component}' | xargs -n1 | sort -u | xargs`)
DC_COUNT=${#FOUND_DC[@]}
DC_MESSAGE="[$DC_COUNT/$COMPONENTS_COUNT] deployment configs found."

if [[ $DC_COUNT -ne $COMPONENTS_COUNT ]]; then
  echo "Error - $DC_MESSAGE"
  EXIT_CODE=1

  # check which DC are missing
  for dc in "${NEEDED_COMPONENTS[@]}"; do
    if [[ ! ( ${FOUND_DC[@]} =~ $dc ) ]]; then

      PRINTED_DC=`echo $dc | cut -d"[" -f 1 | rev | cut -c 2- | rev`
      echo " ! deployment config for $PRINTED_DC is missing..."
    fi
  done

  echo "* Please rerun the deployer to generate missing deployment configs."
else
  echo "Success - $DC_MESSAGE"
fi

echo $TEST_DIVIDER
# Check that we have RC

FOUND_RC=(`oc get rc -l logging-infra -o jsonpath='{.items[*].metadata.labels.component}' | xargs -n1 | sort -u | xargs`)
RC_COUNT=${#FOUND_RC[@]}
RC_MESSAGE="[$RC_COUNT/$COMPONENTS_COUNT] unique replication controllers found."

if [[ $RC_COUNT -ne $COMPONENTS_COUNT ]]; then
  echo "Error - $RC_MESSAGE"
  EXIT_CODE=1

  # check which RC are missing
  for rc in "${NEEDED_COMPONENTS[@]}"; do
    if [[ ! ( ${FOUND_RC[@]} =~ $rc ) ]]; then
      PRINTED_RC=`echo $rc | cut -d"[" -f 1 | rev | cut -c 2- | rev`
      echo " ! unique replication controller for $PRINTED_RC is missing..."
    fi
  done

  #TODO: there is another way to generate the RC from a DC... update message to use that *'if able, otherwise'
  echo "* Please rerun the deployer or redeploy the appropriate DC to generate missing replication controllers."
else
  echo "Success - $RC_MESSAGE"
fi

echo $TEST_DIVIDER
# Check that we have Routes

# we add a '0' to deal with false positives of 'kibana' matching 'kibana' and 'kibana-ops' when checking what is found
NEEDED_ROUTES=("kibana0" "kibana-ops0")
FOUND_ROUTES=(`oc get routes -l logging-infra=support -o jsonpath='{.items[*].metadata.name}'`)
ROUTE_COUNT=${#FOUND_ROUTES[@]}
NEEDED_ROUTE_COUNT=${#NEEDED_ROUTES[@]}
ROUTE_MESSAGE="[$ROUTE_COUNT/$NEEDED_ROUTE_COUNT] routes found."

if [[ $ROUTE_COUNT -ne $NEEDED_ROUTE_COUNT ]]; then
  echo "Error - $ROUTE_MESSAGE"
  EXIT_CODE=1

  for route in "${NEEDED_ROUTES[@]}"; do
    if [[ ! ( ${FOUND_ROUTES[@]} =~ $route ) ]]; then
      echo " ! route ${route%0} is missing..."
    fi
  done

  echo "* Please rerun \`oc process logging-support-template | oc create -f -\` to generate missing routes."
else
  echo "Success - $ROUTE_MESSAGE"
fi

echo $TEST_DIVIDER
# Check that we have Services

# we add a '0' to deal with false positives of when checking what is found, similar to what we do for routes
NEEDED_SERVICE=("logging-es0" "logging-es-cluster0" "logging-es-ops0" "logging-es-ops-cluster0" "logging-kibana0" "logging-kibana-ops0")
FOUND_SERVICE=(`oc get svc -l logging-infra=support -o jsonpath='{.items[*].metadata.name}'`)
SERVICE_COUNT=${#FOUND_SERVICE[@]}
NEEDED_SERVICE_COUNT=${#NEEDED_SERVICE[@]}
SERVICE_MESSAGE="[$SERVICE_COUNT/$NEEDED_SERVICE_COUNT] services found."

if [[ $SERVICE_COUNT -ne $NEEDED_SERVICE_COUNT ]]; then
  echo "Error - $SERVICE_MESSAGE"
  EXIT_CODE=1

  for svc in "${NEEDED_SERVICE[@]}"; do
    if [[ ! ( ${FOUND_SERVICE[@]} =~ $svc ) ]]; then
      echo " ! service ${svc%0} is missing..."
    fi
  done

  echo "* Please rerun \`oc process logging-support-template | oc create -f -\` to generate missing routes."
else
  echo "Success - $SERVICE_MESSAGE"
fi

echo $TEST_DIVIDER
# Check that we have Oauth Client

FOUND_OAUTH=(`oc get oauthclient -l logging-infra=support -o jsonpath='{.items[*].metadata.name}'`)
OAUTH_COUNT=${#FOUND_OAUTH[@]}
NEEDED_OAUTH_COUNT=1
OAUTH_MESSAGE="[$OAUTH_COUNT/$NEEDED_OAUTH_COUNT] oauth clients found."

if [[ $OAUTH_COUNT -ne $NEEDED_OAUTH_COUNT ]]; then
  echo "Error - $OAUTH_MESSAGE"
  echo " ! oauth client kibana-proxy is missing..."
  EXIT_CODE=1

  echo "* Please rerun \`oc process logging-support-template | oc create -f -\` to generate missing oauth client."
else
  echo "Success - $OAUTH_MESSAGE"
fi

echo $TEST_DIVIDER
# Check that we have the fluentd DaemonSet

FOUND_DAEMONSET=(`oc get daemonset -l logging-infra=fluentd -o jsonpath='{.items[*].metadata.name}'`)
DAEMONSET_COUNT=${#FOUND_DAEMONSET[@]}
NEEDED_DAEMONSET_COUNT=1
DAEMONSET_MESSAGE="[$DAEMONSET_COUNT/$NEEDED_DAEMONSET_COUNT] daemonsets found."

if [[ $DAEMONSET_COUNT -ne $NEEDED_DAEMONSET_COUNT ]]; then
  echo "Error - $DAEMONSET_MESSAGE"
  echo " ! daemonset logging-fluentd is missing..."
  EXIT_CODE=1

  echo "* Please rerun \`oc process logging-fluentd-template | oc create -f -\` to generate missing daemonset."
else
  echo "Success - $DAEMONSET_MESSAGE"
fi

echo $TEST_DIVIDER
# Check that Pods are running
# we want to only look for currently running pods
waitFor "[[ ${#NEEDED_COMPONENTS[@]} -eq \$(oc get pods -o jsonpath='{.items[*].metadata.labels.deployment}' | wc -w) ]]"
if [[ $? -ne 0 ]]; then
  echo "Timed out waiting for triggered deployments to complete..."
  # should this exit?
fi

NEEDED_PODS=("${NEEDED_COMPONENTS[@]}" logging-fluentd)
FOUND_PODS=(`oc get pods -l component,provider=openshift -o jsonpath='{.items[?(.status.phase=="Running")].metadata.name}'`)
POD_COUNT=${#FOUND_PODS[@]}
POD_MESSAGE="[$POD_COUNT/$((COMPONENTS_COUNT + ADDITIONAL_PODS))] running pods found."

if [[ $POD_COUNT -ne $((COMPONENTS_COUNT + ADDITIONAL_PODS)) ]]; then
  echo "Error - $POD_MESSAGE"
  EXIT_CODE=1

  # check which pods are missing
  for pod in "${NEEDED_PODS[@]}"; do
    if [[ ! ( ${FOUND_PODS[@]} =~ $pod ) ]]; then
      PRINTED_POD=`echo $pod | cut -d"[" -f 1 | rev | cut -c 2- | rev`
      echo " ! pod for $PRINTED_POD is not currently running..."
    fi
  done

  echo "* Please ensure the number of replicas for your DC and RC are at least 1."
  echo "* If the fluentd pod is missing, please ensure your node is tagged appropriately."
else
  echo "Success - $POD_MESSAGE"
fi

echo $TEST_DIVIDER
echo "Checking for ES and Kibana successful starts"
## Add check to Kibana and ES that they started up correctly
for pod in $(oc get pods -l component=es -o name); do
  checkESStarted "$pod" || EXIT_CODE=1
done
for pod in $(oc get pods -l component=es-ops -o name); do
  checkESStarted "$pod" || EXIT_CODE=1
done

for pod in $(oc get pods -l component=kibana -o name); do
  checkKibanaStarted "$pod" || EXIT_CODE=1
done
for pod in $(oc get pods -l component=kibana-ops -o name); do
  checkKibanaStarted "$pod" || EXIT_CODE=1
done

echo $TEST_DIVIDER
exit $EXIT_CODE

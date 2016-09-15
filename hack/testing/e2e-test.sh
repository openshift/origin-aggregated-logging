#!/bin/bash

if [[ $# -ne 1 ]]; then
  # assuming not using OPS cluster
  CLUSTER="false"
else
  CLUSTER="$1"
fi

KIBANA_CLUSTER_SIZE=${KIBANA_CLUSTER_SIZE:=1}
KIBANA_OPS_CLUSTER_SIZE=${KIBANA_OPS_CLUSTER_SIZE:=1}
ES_CLUSTER_SIZE=${ES_CLUSTER_SIZE:=1}
ES_OPS_CLUSTER_SIZE=${ES_OPS_CLUSTER_SIZE:=1}

echo "Checking installation of the EFK stack..."
KIBANA_CLUSTER_SIZE=$KIBANA_CLUSTER_SIZE KIBANA_OPS_CLUSTER_SIZE=$KIBANA_OPS_CLUSTER_SIZE ES_CLUSTER_SIZE=$ES_CLUSTER_SIZE ES_OPS_CLUSTER_SIZE=$ES_OPS_CLUSTER_SIZE ./check-EFK-running.sh "$CLUSTER"

if [[ $? -eq 0 ]]; then
  echo "Checking for log entry matches between ES and their sources..."
  ./check-logs.sh "$CLUSTER"
else
  echo "Errors found when checking installation of the EFK stack -- not checking log entry matches. Please resolve errors and retest."
  exit 1
fi

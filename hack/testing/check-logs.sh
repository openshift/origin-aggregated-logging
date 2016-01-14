#!/bin/bash

if [[ $VERBOSE ]]; then
  set -ex
else
  set -e
fi

if [[ $# -ne 1 ]]; then
  # assuming not using OPS cluster
  CLUSTER="false"
else
  CLUSTER="$1"
fi

TIMES=${TIMES:=10}
QUERY_SIZE=${QUERY_SIZE:=500}
TEST_DIVIDER="------------------------------------------"

# we need logic for ES_OPS
KIBANA_POD=`oc get pods | grep 'logging-kibana-[0-9]' | grep -v -- "-build" | cut -d" " -f 1`
KIBANA_OPS_POD=`oc get pods | grep 'logging-kibana-ops-[0-9]' | cut -d" " -f 1`
ES_SVC=`oc get svc | grep '^logging-es ' | awk '{print $2 ":" $4}' | rev | cut -c 5- | rev`
ES_OPS_SVC=`oc get svc | grep '^logging-es-ops ' | awk '{print $2 ":" $4}' | rev | cut -c 5- | rev`

# get names of the ES pods to check their logs
PODS=(`oc get pods | grep 'logging-es-' | grep 'Running' | cut -d" " -f 1`)

# check each container's logs for indices created by fluentd
for pod in "${PODS[@]}"; do
  INDICES=(`oc logs $pod | grep 'update_mapping \[fluentd\]' | cut -d"[" -f 6 | cut -d"]" -f 1 | rev | cut -d"." -f 4- | rev | sort | uniq`)
  INDEX_COUNT=${#INDICES[@]}

  if [[ $INDEX_COUNT -eq 0 ]]; then
    # if we have no indices created -- we have nothing to check
    echo " ! no log indices found"
  else
    # indexes were created -- we should check logs here
    echo "   found $INDEX_COUNT index(es) [${INDICES[@]}]"
    echo $TEST_DIVIDER

    for index in "${INDICES[@]}"; do
      # if index is ".operations.*" then we check syslog
      if [[ "$index" == ".operations" ]]; then
        # search /var/log/messages*
        FILE_PATH="/var/log/messages*"

        if [[ "$CLUSTER" == "true" ]]; then
          ES="$ES_OPS_SVC"
          KIBANA="$KIBANA_OPS_POD"
        else
          ES="$ES_SVC"
          KIBANA="$KIBANA_POD"
        fi

      else
        # if index is anything else, then we check container logs (where namespace is index)
        FILE_PATH="/var/log/containers/*_${index}_*.log"
        ES="$ES_SVC"
        KIBANA="$KIBANA_POD"
      fi

      KIBANA=`echo $KIBANA | cut -d" " -f 1`
      ES=`echo $ES | cut -d" " -f 1`
      ES_NAME=$(oc get svc | grep `echo $ES | cut -d":" -f 1` | cut -d" " -f 1)

      READY=0
      # Before we try to get logs from $KIBANA we should make sure it has properly started up e.g. it has connected to ES successfully -> ES is up
      for i in $(seq 1 $TIMES); do
        if [[ ! -z `oc logs $KIBANA -c kibana | grep 'Listening on 0.0.0.0:5601'` ]]; then
          READY=1
          break
        fi

        sleep 1
        echo "Waiting for $ES_NAME to be ready to query..."
      done

      if [[ $READY -eq 1 ]]; then
        go run check-logs.go "$KIBANA" "$ES" "$index" "$FILE_PATH" "$QUERY_SIZE"
        echo $TEST_DIVIDER
      else
        echo "$ES_NAME not ready to be queried within $TIMES attempts..."
      fi

    done

  fi

done

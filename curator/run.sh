#!/bin/bash

if [ "$CURATOR_SCRIPT_LOG_LEVEL" = DEBUG ] ; then
    set -x
fi

if [ "$CURATOR_LOG_LEVEL" = WARN ] ; then
    export CURATOR_LOG_LEVEL="WARNING"
fi

TIMES=60

function waitForES() {
  for ((i=1; i<=$TIMES; i++ )); do
    # test for ES to be up first
    result=$(curl --cacert $ES_CA --key $ES_CLIENT_KEY --cert $ES_CLIENT_CERT -s -w "%{http_code}" -XGET "https://$ES_HOST:$ES_PORT/" -o /dev/null)
    [[ $result -eq 200 ]] && return 0
    sleep 1
  done

  echo "Was not able to connect to Elasticearch at $ES_HOST:$ES_PORT within $TIMES attempts"
  exit 255
}

waitForES

# Check whether legacy config was supplied
actions_location=${CURATOR_ACTIONS_FILE}
python -u convert.py
# 0 - actions file found
# 1 - actions file generated from legacy config
# 2 - an error occured
case "$?" in
  "1") actions_location=$HOME/actions.yaml
  ;;
  "2") exit 1
  ;;
esac

if [ "$CURATOR_SCRIPT_LOG_LEVEL" = DEBUG ] ; then
  echo "Using the following configuration:"
  echo "---------------------------------------------------------"
  cat $actions_location
  echo "---------------------------------------------------------"
fi

exec curator --config ${CURATOR_CONF_FILE} $actions_location

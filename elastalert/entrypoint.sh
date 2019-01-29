#!/bin/bash

set -euxo pipefail

# export PYTHONPATH for custom modules
colon=${PYTHONPATH:+":"}
export PYTHONPATH="${PYTHONPATH:-}${colon}/home/elastalert"

echo "Verifying rules..."
for rule in $ELASTALERT_RULES/*.yaml ; do
	elastalert-test-rule --schema-only $rule
done

echo "Recreating index..."
elastalert-create-index --config $ELASTALERT_CONFIG

echo "Starting ElastAlert..."
extra_args=""
if [ "${VERBOSE:-false}" = true ] ; then
    extra_args="${extra_args} --verbose"
fi
if [ "${DEBUG:-false}" = true ] ; then
    extra_args="${extra_args} --debug"
fi
exec elastalert ${extra_args} --config $ELASTALERT_CONFIG

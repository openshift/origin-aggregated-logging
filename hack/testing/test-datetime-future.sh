#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}" )/../lib/init.sh"

if [[ $# -eq 1 ]]; then
    # There is an ops cluster set up, so we
    # need to expect to see the log entry in
    # the ops Elasticsearch.
    OAL_ELASTICSEARCH_COMPONENT="es-ops" "${OS_O_A_L_DIR}/test/future_dated_log.sh"
else
    OAL_ELASTICSEARCH_COMPONENT="es" "${OS_O_A_L_DIR}/test/future_dated_log.sh"
fi
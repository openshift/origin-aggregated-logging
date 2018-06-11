#!/bin/bash

# This is a test suite for the logging stack upgrade

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::test::junit::declare_suite_start "test/upgrade"

LOGGING_NS=${LOGGING_NS:-openshift-logging}

get_upgrade_test_uuid() {
    upgrade_test_uuid="$1"
    cp $2 $ARTIFACT_DIR/upgrade-record.json
}

wait_for_fluentd_to_catch_up get_upgrade_test_uuid
es_svc=$( get_es_svc es )

os::cmd::expect_success "cat $ARTIFACT_DIR/upgrade-record.json | \
                         python $OS_O_A_L_DIR/hack/testing/test-json-parsing.py $upgrade_test_uuid"

old_upgrade_test_uuid=$(cat /tmp/upgrade_test_uuid)
os::cmd::expect_success "curl_es $es_svc /project.${LOGGING_NS}.*/_search?q=message:$old_upgrade_test_uuid | \
                         python $OS_O_A_L_DIR/hack/testing/test-json-parsing.py $old_upgrade_test_uuid"

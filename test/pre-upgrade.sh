#!/bin/bash

# This is a test suite for the logging stack upgrade

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::test::junit::declare_suite_start "test/pre-upgrade"

LOGGING_NS=:${LOGGING_NS:-openshift-logging}

#store log messages to file so post-upgrade can validate their existence
store_upgrade_test_uuid() {
    upgrade_test_uuid="$1"
    echo "$1" > /tmp/upgrade_test_uuid
}

wait_for_fluentd_to_catch_up store_upgrade_test_uuid
es_pod=$( get_es_pod es )

os::cmd::expect_success "curl_es $es_pod /project.logging.*/_search?q=message:$upgrade_test_uuid | \
                         python $OS_O_A_L_DIR/hack/testing/test-json-parsing.py $upgrade_test_uuid"

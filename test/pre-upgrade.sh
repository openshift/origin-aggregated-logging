#!/bin/bash

# This is a test suite for the logging stack upgrade

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::test::junit::declare_suite_start "test/pre-upgrade"

#store log messages to file so post-upgrade can validate their existence
store_upgrade_test_uuid() {
    cp $2 $ARTIFACT_DIR/pre-upgrade-record.json
    upgrade_test_uuid="$1"
    echo "$1" > /tmp/upgrade_test_uuid
}

wait_for_fluentd_to_catch_up store_upgrade_test_uuid

os::cmd::expect_success "cat $ARTIFACT_DIR/pre-upgrade-record.json | \
                         python $OS_O_A_L_DIR/hack/testing/test-json-parsing.py $upgrade_test_uuid"

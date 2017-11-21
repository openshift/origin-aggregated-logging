#!/bin/bash

# This is a test suite for the docker audit log feature

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::test::junit::declare_suite_start "test/docker_audit"

function get_logs_count() {
    local es_pod=$1
    local index=$2
    curl_es $es_pod /$index/_count?q=docker.user:* | get_count_from_json
}

function logs_count_is_ge() {
    local es_pod=$1
    local index=$2
    local expected=$3
    local actual=$( get_logs_count $es_pod $index )
    test $actual -ge $expected
}

function is_audit_enabled() {
    oc set env ds/logging-fluentd --list | grep -q \^AUDIT_CONTAINER_ENGINE=true
}

if ! is_audit_enabled ; then
    os::log::info "AUDIT_CONTAINER_ENGINE is disabled on this cluster, skipping this test"
    exit 0
fi
    
# operations index can be in a separate cluster
espod=$( get_es_pod es )
esopspod=$( get_es_pod es-ops )
esopspod=${esopspod:-$espod}
# 
logs_before=$( get_logs_count $espod '/project.*/' )
ops_logs_before=$( get_logs_count $esopspod '/.operations.*/' )

# create,start,delete generates 5 docker audit messages
docker run --rm centos:7 echo ""

os::cmd::try_until_success "logs_count_is_ge $esopspod '/.operations.*/' 5"

ops_logs_after=$( get_logs_count $esopspod '/.operations.*/' )
logs_after=$( get_logs_count $espod '/project.*/' )

ops_diff=$((ops_logs_after-ops_logs_before))
diff=$((logs_after-logs_before))

os::log::info "ops diff:  $ops_diff"
os::log::info "proj diff: $diff"

# just a sanity check
if [ $diff -ne 0 ]; then
    os::log::error "Docker audit logs found in project index. But should only be in .operations index."
fi
os::cmd::expect_success "test $diff -eq 0"

# this is the real deal
# if no messages are found in the ops index it means the deployment failed
if [ $ops_diff -lt 5 ]; then
    os::log::error ".operations index contains difference of $ops_diff messages, but at least 5 are expected."
fi
os::cmd::expect_success "test $ops_diff -ge 5"

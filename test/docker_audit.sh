#!/bin/bash

# This is a test suite for the docker audit log feature

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::test::junit::declare_suite_start "test/docker_audit"

function get_logs_count() {
    local es_svc=$1
    local index="$2"
    curl_es $es_svc "${index}"_count?q=docker.user:* | get_count_from_json
}

function get_logs_source() {
    local es_svc=$1
    local index="$2"
    curl_es $es_svc "${index}"_search?q=docker.user:* | jq .
}

function get_logs_count_timerange() {
    local es_svc=$1
    local index="$2"
    local timestamp="$3"
    curl_es $es_svc "${index}"_count -d '{
        "query": {
            "bool": {
                "must": {
                    "exists": {
                        "field": "docker.user"
                    }
                },
                "filter": {
                    "range" : {
                        "@timestamp" : {
                            "gte" : '\""$timestamp"\"'
                        }
                    }
                }
            }
        }
    }' | get_count_from_json
}

function logs_count_is_ge() {
    local es_svc=$1
    local index="$2"
    local expected=$3
    local timestamp="$4"
    local actual=$( get_logs_count_timerange $es_svc "$index" "$timestamp" )
    test $actual -ge $expected
}

function print_logs() {
    local es_svc=$1
    local index="$2"
    curl_es $es_svc "${index}"_search?q=docker.user:* | jq . | artifact_out
}

function is_audit_enabled() {
    oc set env $fluentd_ds --list | grep -q \^AUDIT_CONTAINER_ENGINE=true
}

if ! is_audit_enabled ; then
    os::log::info "AUDIT_CONTAINER_ENGINE is disabled on this cluster, skipping this test"
    exit 0
fi

# operations index can be in a separate cluster
essvc=$( get_es_svc es )
esopssvc=$( get_es_svc es-ops )
esopssvc=${esopssvc:-$essvc}

fpod=$( get_running_pod fluentd )
stop_fluentd "$fpod" $((second * 180)) 2>&1 | artifact_out

logs_before=$( get_logs_count $essvc '/project.*/' )
ops_logs_before=$( get_logs_count $esopssvc '/.operations.*/' )

os::log::info "ops diff before:  $ops_logs_before"
os::log::info "proj diff before: $logs_before"

start_fluentd true $((second * 180)) 2>&1 | artifact_out

fpod=$( get_running_pod fluentd )

# ping,create,attach,start generates 4 docker audit messages
timestamp=$( date --iso-8601=seconds )
docker run --rm centos:7 echo "running test container"

if ! os::cmd::try_until_success "logs_count_is_ge $esopssvc '/.operations.*/' 4 $timestamp" $((second * 60)) ; then
    sudo grep VIRT_CONTROL /var/log/audit/audit.log | tail -40 > $ARTIFACT_DIR/docker_audit_audit.log
    get_fluentd_pod_log $fpod > $ARTIFACT_DIR/docker_audit_fluentd.log
    ops_logs_after=$( get_logs_count $esopssvc '/.operations.*/' )
    logs_after=$( get_logs_count $essvc '/project.*/' )
    get_logs_source $esopssvc '/.operations.*/' > $ARTIFACT_DIR/docker_audit_ops.json 2>&1
    get_logs_source $essvc '/project.*/' > $ARTIFACT_DIR/docker_audit_proj.json 2>&1

    ops_diff=$((ops_logs_after-ops_logs_before)) || :
    diff=$((logs_after-logs_before)) || :

    os::log::info "ops diff after:  $ops_diff"
    os::log::info "proj diff after: $diff"

    # just a sanity check
    if [ $diff -ne 0 ]; then
        os::log::error "Docker audit logs found in project index. But should only be in .operations index."
    fi

    # this is the real deal
    # if no messages are found in the ops index it means the deployment failed
    if [ $ops_diff -lt 4 ]; then
        os::log::error ".operations index contains difference of $ops_diff messages, but at least 4 are expected."
    fi
fi

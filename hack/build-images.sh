#!/bin/bash

source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

function cleanup() {
    return_code=$?
    os::util::describe_return_code "${return_code}"
    exit "${return_code}"
}
trap "cleanup" EXIT

tag_prefix="${OS_IMAGE_PREFIX:-"openshift/origin"}"
os::build::image "${tag_prefix}-logging-fluentd"       fluentd
os::build::image "${tag_prefix}-logging-elasticsearch" elasticsearch
os::build::image "${tag_prefix}-logging-kibana"        kibana
os::build::image "${tag_prefix}-logging-curator"       curator
os::build::image "${tag_prefix}-logging-auth-proxy"          kibana-proxy

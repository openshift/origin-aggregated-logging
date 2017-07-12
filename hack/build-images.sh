#!/bin/bash

source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

function cleanup() {
    return_code=$?
    os::util::describe_return_code "${return_code}"
    exit "${return_code}"
}
trap "cleanup" EXIT

tag_prefix="${OS_IMAGE_PREFIX:-"openshift/origin"}"
docker_suffix=''
if [ "${RELEASE_STREAM:-}" = 'prod' ] ; then
  docker_suffix='.rhel7'
fi
dockerfile="Dockerfile${docker_suffix}"

OS_BUILD_IMAGE_ARGS="-f fluentd/${dockerfile}" os::build::image "${tag_prefix}-logging-fluentd"             fluentd
OS_BUILD_IMAGE_ARGS="-f elasticsearch/${dockerfile}" os::build::image "${tag_prefix}-logging-elasticsearch" elasticsearch
OS_BUILD_IMAGE_ARGS="-f kibana/${dockerfile}" os::build::image "${tag_prefix}-logging-kibana"               kibana
OS_BUILD_IMAGE_ARGS="-f curator/${dockerfile}" os::build::image "${tag_prefix}-logging-curator"             curator
OS_BUILD_IMAGE_ARGS="-f kibana-proxy/Dockerfile" os::build::image "${tag_prefix}-logging-auth-proxy"     kibana-proxy

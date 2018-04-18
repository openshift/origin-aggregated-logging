#!/bin/bash

source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

function cleanup() {
    return_code=$?
    os::util::describe_return_code "${return_code}"
    exit "${return_code}"
}
trap "cleanup" EXIT

tag_prefix="${OS_IMAGE_PREFIX:-"openshift/origin-"}"
docker_suffix='.centos7'
if [ "${RELEASE_STREAM:-}" = 'prod' ] ; then
  docker_suffix=''
fi
dockerfile="Dockerfile${docker_suffix}"

curbranch=$( git rev-parse --abbrev-ref HEAD )
if [ "${curbranch:-master}" = es5.x ] ; then
  name_suf="5"
fi
OS_BUILD_IMAGE_ARGS="-f fluentd/${dockerfile}" os::build::image "${tag_prefix}logging-fluentd"             fluentd
OS_BUILD_IMAGE_ARGS="-f elasticsearch/${dockerfile}" os::build::image "${tag_prefix}logging-elasticsearch${name_suf:-}" elasticsearch
OS_BUILD_IMAGE_ARGS="-f kibana/${dockerfile}" os::build::image "${tag_prefix}logging-kibana${name_suf:-}"               kibana
OS_BUILD_IMAGE_ARGS="-f curator/${dockerfile}" os::build::image "${tag_prefix}logging-curator${name_suf:-}"             curator
OS_BUILD_IMAGE_ARGS="-f kibana-proxy/${dockerfile}" os::build::image "${tag_prefix}logging-auth-proxy"     kibana-proxy
OS_BUILD_IMAGE_ARGS="-f eventrouter/${dockerfile}" os::build::image "${tag_prefix}logging-eventrouter"     eventrouter

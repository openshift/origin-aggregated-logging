#! /bin/bash

set -euo pipefail

dir=$1
fullimagename=$2

tag_prefix="${OS_IMAGE_PREFIX:-"openshift/origin-"}"
docker_suffix='.origin'

if [ "${RELEASE_STREAM:-}" = 'prod' ] ; then
  docker_suffix=''
fi
dockerfile="Dockerfile${docker_suffix}"

dfpath=${dir}/${dockerfile}

buildargs=""
if [ "$dir" = "elasticsearch" ] ; then
  buildargs="--build-arg OPENSHIFT_CI=true"
fi

podman build $buildargs -f $dfpath -t "$fullimagename" $dir

#! /bin/bash

set -euo pipefail

dir=$1
fullimagename=$2
tag_prefix="${OS_IMAGE_PREFIX:-"openshift/origin-"}"
dfpath=${dir}/Dockerfile

echo "----------------------------------------------------------------------------------------------------------------"
echo "-                                                                                                              -"
echo "Building image $dir - this may take a few minutes until you see any output..."
echo "-                                                                                                              -"
echo "----------------------------------------------------------------------------------------------------------------"
buildargs=""
if [ "$dir" = "elasticsearch" ] ; then
  buildargs="--build-arg OPENSHIFT_CI=true"
fi

podman --cgroup-manager=cgroupfs build $buildargs -f $dfpath -t "$fullimagename" $dir

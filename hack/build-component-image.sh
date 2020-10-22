#! /bin/bash

set -euo pipefail

dir=$1
fullimagename=$2

tag_prefix="${OS_IMAGE_PREFIX:-"openshift/origin-"}"

docker_suffix=''
if [ "${fullimagename}" = "openshift/origin-logging-elasticsearch6" ]; then
  docker_suffix='.origin'
fi

# TODO(periklis)
# Remove this when all Dockerfile.rhel8
# are renamed back to Dockerfile
if [ "${fullimagename}" = 'openshift/origin-logging-kibana6' ]; then
    docker_suffix='.rhel8'
fi

dockerfile="Dockerfile${docker_suffix}"

dfpath=${dir}/${dockerfile}

echo "----------------------------------------------------------------------------------------------------------------"
echo "-                                                                                                              -"
echo "Building image $dir - this may take a few minutes until you see any output..."
echo "-                                                                                                              -"
echo "----------------------------------------------------------------------------------------------------------------"
podman build -f $dfpath -t "$fullimagename" $dir

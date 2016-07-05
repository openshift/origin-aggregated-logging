#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

STARTTIME=$(date +%s)

prefix="${PREFIX:-docker.io/openshift/origin-}"
version="${OS_TAG:-latest}" 

source_root=$(dirname "${0}")/..

#################################
declare -A source_for=(
  [logging-fluentd]=fluentd
  [logging-elasticsearch]=elasticsearch
  [logging-kibana]=kibana
  [logging-curator]=curator
  [logging-auth-proxy]=kibana-proxy
  [logging-deployer]=deployer
  [logging-deployment]=deployer
)
for component in ${!source_for[@]} ; do
  BUILD_STARTTIME=$(date +%s)
  comp_path=$source_root/${source_for[$component]}
  docker_tag=${prefix}${component}:${version}
  echo
  echo
  echo "--- Building component '$comp_path' with docker tag '$docker_tag' ---"
  docker build -t $docker_tag       $comp_path
  BUILD_ENDTIME=$(date +%s); echo "--- $docker_tag took $(($BUILD_ENDTIME - $BUILD_STARTTIME)) seconds ---"
  echo
  echo
done

echo
echo
echo "++ Active images"
docker images | grep ${prefix}logging | grep ${version} | sort
echo


ret=$?; ENDTIME=$(date +%s); echo "$0 took $(($ENDTIME - $STARTTIME)) seconds"; exit "$ret"

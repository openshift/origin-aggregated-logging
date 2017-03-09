#!/bin/bash

# This script builds and pushes a release to DockerHub.

set -o errexit
set -o nounset
set -o pipefail

OS_ROOT=$(dirname "${BASH_SOURCE}")/..
source "${OS_ROOT}/hack/common.sh"

# Go to the top of the tree.
cd "${OS_ROOT}"

tag="${OS_TAG:-}"
if [[ -z "${tag}" ]]; then
  if [[ "$( git tag --points-at HEAD | wc -l )" -ne 1 ]]; then
    os::log::error "Specify OS_TAG or ensure the current git HEAD is tagged."
    exit 1
  fi
  tag="$( git tag --points-at HEAD )"
elif [[ "$( git rev-parse "${tag}" )" != "$( git rev-parse HEAD )" ]]; then
  os::log::warn "You are running a version of hack/release.sh that does not match OS_TAG - images may not be build correctly"
fi

docker pull openshift/origin:v1.1.6
docker pull openshift/base-centos7
docker pull centos:centos7

hack/build-release.sh
OS_TAG=${tag} hack/build-images.sh
OS_PUSH_TAG="${tag}" OS_TAG="${tag}" OS_PUSH_LOCAL="1" hack/push-release.sh

echo
echo "Pushed ${tag} to DockerHub"
echo "1. Push tag to GitHub with: git push origin --tags # (ensure you have no extra tags in your environment)"

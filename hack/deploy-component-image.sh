#!/bin/bash

set -euo pipefail

IMAGE_TAG=$1

echo "Setting up port-forwarding to remote registry ..."
coproc oc -n openshift-image-registry port-forward service/image-registry 5000:5000
trap "kill -15 $COPROC_PID" EXIT
read PORT_FORWARD_STDOUT <&"${COPROC[0]}"
if [[ "$PORT_FORWARD_STDOUT" =~ ^Forwarding.*5000$ ]] ; then
    user=$(oc whoami | sed s/://)
    echo "Login to registry..."
    podman login --tls-verify=false -u ${user} -p $(oc whoami -t) 127.0.0.1:5000

    echo "Pushing image ${IMAGE_TAG} ..."
    if podman push --tls-verify=false ${IMAGE_TAG} 127.0.0.1:5000/${IMAGE_TAG}; then
        oc -n openshift get imagestreams | grep $IMAGE_TAG
    fi
else
    echo "Unexpected message from oc port-forward: $PORT_FORWARD_STDOUT"
fi
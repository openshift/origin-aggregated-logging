#!/bin/bash

set -ex

prefix=${PREFIX:-${1:-openshift/origin-}}
version=${VERSION:-${2:-latest}}
for component in fluentd elasticsearch kibana deployment curator ; do
    docker build -t "${prefix}logging-${component}:${version}"       ../$component/
done
if [ -n "${PUSH:-$3}" ]; then
    for component in fluentd elasticsearch kibana deployment curator ; do
	    docker push "${prefix}logging-${component}:${version}"
    done
fi

#!/bin/bash

set -ex

prefix=${PREFIX:-${1:-openshift/origin-}}
version=${VERSION:-${2:-latest}}
docker build -t "${prefix}logging-fluentd:${version}"       ../fluentd/
docker build -t "${prefix}logging-elasticsearch:${version}" ../elasticsearch/
docker build -t "${prefix}logging-kibana:${version}"        ../kibana/
docker build -t "${prefix}logging-deployment:${version}"    ../deployment/

if [ -n "${PUSH:-$3}" ]; then
	docker push "${prefix}logging-fluentd:${version}"
	docker push "${prefix}logging-elasticsearch:${version}"
	docker push "${prefix}logging-kibana:${version}"
	docker push "${prefix}logging-deployment:${version}"
fi

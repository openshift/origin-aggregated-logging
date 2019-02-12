# Dockerfile to bootstrap build and test in openshift-ci
# this is different than Dockerfile, which is only intended
# to be used in the api.ci environment
# use this Dockerfile for developer builds/testing

FROM openshift/origin-release:golang-1.10

RUN yum -y install epel-release && \
  yum -y install jq bc sudo httpd-tools procps-ng coreutils

RUN mkdir -p /go/src/github.com/openshift/origin-aggregated-logging/
ADD Makefile /go/src/github.com/openshift/origin-aggregated-logging/
ADD openshift/ /go/src/github.com/openshift/origin-aggregated-logging/openshift/
ADD hack/ /go/src/github.com/openshift/origin-aggregated-logging/hack/
ADD test/ /go/src/github.com/openshift/origin-aggregated-logging/test/
ADD fluentd/ /go/src/github.com/openshift/origin-aggregated-logging/fluentd/

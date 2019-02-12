# Dockerfile to bootstrap build and test in openshift-ci

FROM openshift/origin-release:golang-1.10

RUN yum -y install epel-release && \
  yum -y install jq bc sudo httpd-tools procps-ng

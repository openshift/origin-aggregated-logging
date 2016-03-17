#!/bin/bash

set -ex

rpm -q epel-release || yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y --setopt=tsflags=nodocs \
  python-pip \
  PyYAML
pip install elasticsearch-curator python-crontab
yum clean all

mkdir -p ${HOME}
mkdir -p ${CURATOR_CONF_LOCATION}
touch ${CURATOR_CONF_LOCATION}/settings

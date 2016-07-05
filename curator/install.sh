#!/bin/bash

set -ex

rpm -q epel-release || yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y --setopt=tsflags=nodocs \
  python-pip \
  PyYAML
pip install 'elasticsearch-curator<4.0' python-crontab
yum clean all

mkdir -p ${HOME}
mkdir -p $(dirname "$CURATOR_CONF_LOCATION")
touch ${CURATOR_CONF_LOCATION}

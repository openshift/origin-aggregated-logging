#!/bin/bash

set -ex

yum install -y epel-release
yum install -y --setopt=tsflags=nodocs \
  python-pip \
  PyYAML \
  pytz
pip install 'elasticsearch-curator<4.0' python-crontab
yum clean all

mkdir -p ${HOME}
mkdir -p $(dirname "$CURATOR_CONF_LOCATION")
touch ${CURATOR_CONF_LOCATION}

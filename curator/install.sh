#!/bin/bash

set -ex

rpm -q epel-release || yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y --setopt=tsflags=nodocs \
  python-pip \
  PyYAML
pip install elasticsearch-curator python-crontab
yum clean all

# HACK HACK HACK - remove when fixed upstream
yum install -y --setopt=tsflags=nodocs \
    git
git clone -b issue-344 https://github.com/richm/elasticsearch-py.git
pushd elasticsearch-py
python setup.py install
popd
git clone -b issue-520 https://github.com/richm/curator.git
pushd curator
python setup.py install
popd
yum clean all
# HACK HACK HACK - remove when fixed upstream

mkdir -p ${HOME}
mkdir -p ${CURATOR_CONF_LOCATION}
touch ${CURATOR_CONF_LOCATION}/settings

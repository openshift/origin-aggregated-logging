#!/bin/bash

set -euxo pipefail

ESO_OPERATOR_REPO=${ESO_OPERATOR_REPO:-'openshift'}
ESO_OPERATOR_BRANCH=${ESO_OPERATOR_BRANCH:-'master'}
CLO_OPERATOR_REPO=${CLO_OPERATOR_REPO:-'openshift'}
CLO_OPERATOR_BRANCH=${CLO_OPERATOR_BRANCH:-'master'}

pushd /tmp
GOPATH=${GOPATH:-/root/golang}
export GOPATH=$GOPATH
export PATH=$GOPATH/bin:$PATH

if [ ! -d $GOPATH/bin ] ; then
    mkdir -p $GOPATH/bin
fi
if [ ! -d $GOPATH/src/github.com/openshift ] ; then
    mkdir -p $GOPATH/src/github.com/openshift
fi
if [ ! -d $GOPATH/src/github.com/operator-framework ] ; then
    mkdir -p $GOPATH/src/github.com/operator-framework
fi

type -p git || sudo yum install -y git

needgo=1
case "$( go version 2>&1 || : )" in
*go1.10.*) needgo= ;;
esac
if [ -n "$needgo" ] ; then
    sudo curl https://dl.google.com/go/go1.10.5.linux-amd64.tar.gz -o go1.10.5.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.10.5.linux-amd64.tar.gz
    export PATH=/usr/local/go/bin:$PATH
fi
type -p dep || { sudo curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh ; }

type -p imagebuilder || go get -u github.com/openshift/imagebuilder/cmd/imagebuilder

popd

if [ ! -d $GOPATH/src/github.com/openshift/elasticsearch-operator ] ; then
  git clone https://github.com/$ESO_OPERATOR_REPO/elasticsearch-operator \
    --branch $ESO_OPERATOR_BRANCH \
    $GOPATH/src/github.com/openshift/elasticsearch-operator
fi
if [ ! -d $GOPATH/src/github.com/openshift/cluster-logging-operator ] ; then
  git clone https://github.com/$CLO_OPERATOR_REPO/cluster-logging-operator \
    --branch $CLO_OPERATOR_BRANCH \
    $GOPATH/src/github.com/openshift/cluster-logging-operator
fi

if [ ! -d $GOPATH/src/github.com/operator-framework/operator-sdk ] ; then
  git clone https://github.com/operator-framework/operator-sdk \
  --branch master \
  $GOPATH/src/github.com/operator-framework/operator-sdk
fi
if ! type -p operator-sdk ; then
    pushd $GOPATH/src/github.com/operator-framework/operator-sdk
    make dep
    # make install fails in mysterious ways
    make install || sudo make install || {
      cd commands/operator-sdk
      go install || sudo go install
    }
    popd
fi

echo "export GOPATH=$GOPATH" >> ~/.bashrc
echo "export PATH=$PATH" >> ~/.bashrc

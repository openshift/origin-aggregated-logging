#!/bin/bash

ESO_OPERATOR_REPO={ESO_OPERATOR_REPO:-'openshift'}
ESO_OPERATOR_BRANCH={ESO_OPERATOR_BRANCH:-'master'}
CLO_OPERATOR_REPO={CLO_OPERATOR_REPO:-'openshift'}
CLO_OPERATOR_BRANCH={CLO_OPERATOR_BRANCH:-'master'}

pushd /tmp
GOPATH=${GOPATH:-/root/golang}
export GOPATH=$GOPATH

mkdir -p $GOPATH/bin
mkdir -p $GOPATH/src/github.com/openshift
mkdir -p $GOPATH/src/github.com/operator-framework

sudo yum install -y git
sudo curl https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz -o go1.10.3.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.10.3.linux-amd64.tar.gz

export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
sudo curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
popd

pushd $GOPATH/src/github.com/operator-framework
git clone https://github.com/operator-framework/operator-sdk
popd

pushd $GOPATH/src/github.com/operator-framework/operator-sdk
git checkout master
make dep
make install
popd

pushd $GOPATH/src/github.com/openshift
git clone https://github.com/$ESO_OPERATOR_REPO/elasticsearch-operator --branch $ESO_OPERATOR_BRANCH
git clone https://github.com/$CLO_OPERATOR_REPO/cluster-logging-operator --branch $CLO_OPERATOR_BRANCH
popd

echo "export GOPATH=$GOPATH" >> ~/.bashrc
echo "export PATH=$PATH" >> ~/.bashrc

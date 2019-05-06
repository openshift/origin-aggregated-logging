#!/bin/bash

set -euo pipefail

if [ -z "${OPENSHIFT_INSTALL_PULL_SECRET_PATH:-}" ] ; then
    echo ERROR: You must provide a pull secret
    echo specify a path to the file in \$OPENSHIFT_INSTALL_PULL_SECRET_PATH
    echo the file should be the file downloaded from https://cloud.openshift.com/clusters/install
    echo Step 4: Deploy the Cluster - Download Pull Secret
    exit 1
fi

if [ -z "${WORKDIR:-}" ] ; then
    echo ERROR: you must provide \$WORKDIR into which the new cluster
    echo auth credentials will be written - the installer will create
    echo \$WORKDIR/auth/kubeadmin-password and kubeconfig
    exit 1
elif [ ! -d $WORKDIR ] ; then
    mkdir -p $WORKDIR
fi

installdir=$WORKDIR/installdir
if [ ! -d $installdir ] ; then
    mkdir -p $installdir
fi

OPENSHIFT_INSTALL_PLATFORM_ARCH=${OPENSHIFT_INSTALL_PLATFORM_ARCH:-linux-amd64}
OPENSHIFT_INSTALL_PLATFORM=${OPENSHIFT_INSTALL_PLATFORM:-aws}
OPENSHIFT_INSTALL_SSH_PUB_KEY_PATH=${OPENSHIFT_INSTALL_SSH_PUB_KEY_PATH:-$HOME/.ssh/id_rsa.pub}
OPENSHIFT_INSTALL_NUM_WORKERS=${OPENSHIFT_INSTALL_NUM_WORKERS:-3}
OPENSHIFT_INSTALL_NUM_MASTERS=${OPENSHIFT_INSTALL_NUM_MASTERS:-3}

if [ $OPENSHIFT_INSTALL_PLATFORM = aws ] ; then
    OPENSHIFT_INSTALL_BASE_DOMAIN=${OPENSHIFT_INSTALL_BASE_DOMAIN:-devcluster.openshift.com}
    OPENSHIFT_INSTALL_CLUSTER_NAME=${OPENSHIFT_INSTALL_CLUSTER_NAME:-${USER}-log}
    OPENSHIFT_INSTALL_AWS_REGION=${OPENSHIFT_INSTALL_AWS_REGION:-us-east-1}
    export AWS_PROFILE=${AWS_PROFILE:-default}
fi

if [ -n "${OPENSHIFT_INSTALL_VERSION:-}" ] ; then
    # download and use specific version
    INSTALLER=$installdir/openshift-install
    url=https://github.com/openshift/installer/releases/download/${OPENSHIFT_INSTALL_VERSION}/openshift-install-${OPENSHIFT_INSTALL_PLATFORM_ARCH}
    curl -s -L -o $INSTALLER $url
else
    pkgstoinstall=""
    for pkg in golang-bin gcc-c++ libvirt-devel ; do
        if ! rpm -q $pkg > /dev/null 2>&1 ; then
            pkgstoinstall="$pkgstoinstall $pkg"
        fi
    done
    if [ -n "$pkgstoinstall" ] ; then
        yum -y install $pkgstoinstall
    fi
    if [ -d $GOPATH/src/github.com/openshift/installer ] ; then
        pushd $GOPATH/src/github.com/openshift/installer > /dev/null
        git pull
    else
        pushd $installdir > /dev/null
        git clone https://github.com/openshift/installer
        cd installer
    fi
    hack/build.sh
    INSTALLER=$( pwd )/bin/openshift-install
    popd > /dev/null
fi

pushd $installdir > /dev/null

if [ $OPENSHIFT_INSTALL_PLATFORM = aws ] ; then
    cat > install-config.yaml <<EOF
apiVersion: v1beta3
baseDomain: $OPENSHIFT_INSTALL_BASE_DOMAIN
clusterID: $( uuidgen )
machines:
- name: master
  platform: {}
  replicas: $OPENSHIFT_INSTALL_NUM_MASTERS
- name: worker
  platform: {}
  replicas: $OPENSHIFT_INSTALL_NUM_WORKERS
metadata:
  name: ${OPENSHIFT_INSTALL_CLUSTER_NAME}
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14
    hostSubnetLength: 9
  machineCIDR: 10.0.0.0/16
  serviceCIDR: 172.30.0.0/16
  type: OpenshiftSDN
platform:
  aws:
    region: $OPENSHIFT_INSTALL_AWS_REGION
pullSecret: '$( cat $OPENSHIFT_INSTALL_PULL_SECRET_PATH )'
sshKey: |
  $( cat $OPENSHIFT_INSTALL_SSH_PUB_KEY_PATH )
EOF
fi

if $INSTALLER --dir $installdir create cluster ; then
    cp -r $installdir/auth $WORKDIR
else
    echo ERROR: installation failed - cleaning up cluster
    $INSTALLER --dir $installdir destroy cluster || :
    exit 1
fi

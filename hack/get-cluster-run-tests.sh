#!/bin/bash

# The purpose of this script is to provision an OpenShift cluster, build the latest
# images from local source (images and/or operators), deploy logging, and
# and run the logging CI tests on it.

set -euxo pipefail

usage() {
    local bn=$( basename $0 )
    cat <<EOF
Usage: [ENV_VAR=val ....] $0

# Pre-requisites:

Assumes you have GOPATH set.

Assumes you have the following repos cloned from https://github.com/openshift/
under $GOPATH/src/github/openshift:

- origin-aggregated-logging
- elasticsearch-operator
- cluster-logging-operator
- installer

Optional but recommended, under same location:

- shared-secrets
- release

# Config files

Use $HOME/.config/$bn to set environment variables.

# Environment variables:

WORKDIR - default is a tmp dir - set this if you want to keep your cluster
files in a known location so that you can easily destroy the cluster
after use e.g. you will need to manually do

/path/to/openshift/install/bin/openshift-install --dir $WORKDIR/installdir destroy cluster

after you are done.

BUILD_IMAGES - default is true - set to false if you want to skip building the
images e.g. if you have already built them - this step takes a long time

DEPLOY_CLUSTER - default is true - set to false if you already have a cluster

PUSH_IMAGES - default is true - set to false if you didn't BUILD_IMAGES or
otherwise will pull images from somewhere else

TEST_LOGGING - default is true - set to false if you do not want to deploy
logging and run the logging CI tests

OPENSHIFT_INSTALL_PULL_SECRET_PATH - no default - this is the absolute path
of the file containing the pull secrets used with the openshift-installer
to deploy the cluster.  If DEPLOY_CLUSTER=true, you must have set
OPENSHIFT_INSTALL_PULL_SECRET_PATH.  For example

OPENSHIFT_INSTALL_PULL_SECRET_PATH=$HOME/.pullsecret

where $HOME/.pullsecret contains something like

{"auths":{"cloud.openshift.com":{"auth":"asdjflaskdlfakjsdfljsdfl....

The file should be the file downloaded from https://cloud.openshift.com/clusters/install

OPENSHIFT_INSTALL_SSH_PUB_KEY_PATH - default $HOME/.ssh/id_rsa.pub - also for
DEPLOY_CLUSTER=true

See hack/build-images.sh and hack/deploy-openshift-cluster.sh for more environment
variables you might find useful.
EOF
}

get_component_run_cmd() {
    # component is $1 - everything else is a command to run in that directory
    local component=$1 ; shift
    if [ -n "${GOPATH:-}" -a -d ${GOPATH:-}/src/github.com/openshift/$component ] ; then
        pushd $GOPATH/src/github.com/openshift/$component > /dev/null
    elif [ -d $workdir/$component ] ; then
        pushd $workdir/$component > /dev/null
    else
        pushd $workdir > /dev/null
        git clone https://github.com/openshift/$component
        cd $component
    fi
    "$@"
    popd > /dev/null
}

case "${1:-}" in
--h*|-h*) usage ; exit 1 ;;
esac

scriptdir=$( dirname $0 )
scriptname=$( basename $0 )
if [ -f $HOME/.config/$scriptname ] ; then
    . $HOME/.config/$scriptname
fi

workdir=${WORKDIR:-$( mktemp --tmpdir -d logging-XXXXXXXXXX )}
if [ ! -d $workdir ] ; then
    mkdir -p $workdir
fi
#trap "rm -rf $workdir" EXIT

# build images
if [ "${BUILD_IMAGES:-true}" = true ] ; then
    if ! type -p imagebuilder > /dev/null 2>&1 ; then
        echo trying to install imagebuilder . . .
        go get -u github.com/openshift/imagebuilder/cmd/imagebuilder
    fi
    if ! type -p imagebuilder > /dev/null 2>&1 ; then
        echo cannot find imagebuilder - make sure $GOPATH/bin is in your '$PATH'
        exit 1
    fi
    WORKDIR=$workdir $scriptdir/build-images.sh

    for comp in elasticsearch-operator cluster-logging-operator ; do
        WORKDIR=$workdir get_component_run_cmd $comp make image
    done
fi

# deploy openshift
if [ "${DEPLOY_CLUSTER:-true}" = true ] ; then
    WORKDIR=$workdir $scriptdir/deploy-openshift-cluster.sh
fi

# push images to new cluster
if [ "${PUSH_IMAGES:-true}" = true ] ; then
    PUSH_USER=kubeadmin PUSH_PASSWORD=$( cat $workdir/auth/kubeadmin-password ) \
    KUBECONFIG=$workdir/auth/kubeconfig \
    WORKDIR=$workdir PUSH_ONLY=true REMOTE_REGISTRY=true $scriptdir/build-images.sh

    for comp in elasticsearch-operator cluster-logging-operator ; do
        PUSH_USER=kubeadmin PUSH_PASSWORD=$( cat $workdir/auth/kubeadmin-password ) \
        KUBECONFIG=$workdir/auth/kubeconfig SKIP_BUILD=true \
        WORKDIR=$workdir REMOTE_REGISTRY=true get_component_run_cmd $comp make deploy-image
    done
fi

# deploy logging
if [ "${DEPLOY_LOGGING:-true}" = true ] ; then
    KUBECONFIG=$workdir/auth/kubeconfig ARTIFACT_DIR=$workdir/artifacts \
    USE_EO_LATEST_IMAGE=true USE_CLO_LATEST_IMAGE=true \
    $scriptdir/deploy-logging.sh
fi

# run logging tests
if [ "${TEST_LOGGING:-true}" = true ] ; then
    KUBECONFIG=$workdir/auth/kubeconfig ARTIFACT_DIR=$workdir/artifacts \
    USE_EO_LATEST_IMAGE=true USE_CLO_LATEST_IMAGE=true \
    $scriptdir/test-logging.sh
fi

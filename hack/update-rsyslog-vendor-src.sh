#!/bin/bash

set -euo pipefail

for cmd in rhpkg rpmspec ; do
    if ! type -p $cmd > /dev/null ; then
        echo ERROR: $cmd not installed - please install $cmd
        exit 1
    fi
done

curbranch=$( git rev-parse --abbrev-ref HEAD )

pushd $( dirname $0 ) > /dev/null
cd ..
oaldir=$( pwd )
popd > /dev/null

RH_DIST_GIT=${RH_DIST_GIT:-$HOME/rh-dist-git}
if [ ! -d $RH_DIST_GIT ] ; then
    echo INFO: you do not have a local dist-git, so will use a temporary one
    RH_DIST_GIT=$( mktemp -d )
fi
SRC_BRANCH=${SRC_BRANCH:-rhel-8.0.0}
RSYSLOG_VENDOR_DIR=${RSYSLOG_VENDOR_DIR:-$oaldir/rsyslog/vendored_src}
RSYSLOG_VENDOR_BRANCH=${RSYSLOG_VENDOR_BRANCH:-rsyslog-vendor}
pushd $oaldir > /dev/null
git checkout $RSYSLOG_VENDOR_BRANCH
popd > /dev/null

echo This will grab the latest source for rsyslog and dependent packages
echo vendor it into $RSYSLOG_VENDOR_BRANCH, and merge the vendored
echo source into $curbranch

# rsyslog and dependent packages - listed in dependency order
# order doesn't matter here, but does matter at build/install time
# keep it the same for consistency
packages="librelp libestr libfastjson liblognorm librdkafka rsyslog"

for pkg in $packages ; do
    if [ ! -d $RH_DIST_GIT/$pkg ] ; then
        cd $RH_DIST_GIT
        rhpkg co $pkg
        cd $pkg
    else
        cd $RH_DIST_GIT/$pkg
        # make sure we have the latest branches
        git pull
    fi
    rhpkg switch-branch $SRC_BRANCH
    version=$( rpmspec -q --qf '%{version}\n' $pkg.spec | head -1 ) || :
    if [ -z "$version" ] ; then
        echo ERROR: unable to determine version from $pkg.spec
        rpmspec -q --qf '%{version}\n' $pkg.spec
        exit 1
    fi
    rm -rf $pkg-$version
    # unpack src, apply patches, etc. - creates directory $pkg-$version with source
    rhpkg prep
    if [ ! -d $RSYSLOG_VENDOR_DIR ] ; then
        mkdir -p $RSYSLOG_VENDOR_DIR
    fi
    cd $RSYSLOG_VENDOR_DIR
    rm -rf $pkg
    mkdir -p $pkg
    for file in $( git --git-dir=$RH_DIST_GIT/$pkg/.git ls-files ) ; do
        dirname=$( dirname $file )
        if [ ! -d "$pkg/$dirname" ] ; then
            mkdir -p $pkg/$dirname
        fi
        cp $RH_DIST_GIT/$pkg/$file $pkg/$file
    done
    cp -r $RH_DIST_GIT/$pkg/$pkg-$version $pkg
    mv $pkg/$pkg-$version $pkg/$pkg
done

if git diff --exit-code ; then
    echo INFO: rsyslog-vendor source is up-to-date
else
    git commit -a -m "Vendor in latest rsyslog source"
    echo INFO: remember to push rsyslog-vendor branch
fi
git checkout $curbranch
git merge $RSYSLOG_VENDOR_BRANCH

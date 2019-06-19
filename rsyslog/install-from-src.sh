#!/bin/bash

set -euxo pipefail

# must be listed in dependency order
packages="librelp libestr libfastjson liblognorm librdkafka rsyslog"

contents=$( mktemp )
trap "rm -f $contents" EXIT
rpmtopdir=$( pwd )
for pkg in $packages ; do
    cd $pkg
    # SourceN and PatchN should already have been removed from the spec file
    # remove %prep section from rpm spec
    sed -e '/^%prep/,/^%build/{/^%build/!d}' -i $pkg.spec
    rpmspec -q --qf '%{name} %{name} %{version} -\n' $pkg.spec >> $contents
    # put RPMS in ../RPMS - use source code from $pkg dir and build in that dir as well
    rpmbuild -bb --define "_topdir $rpmtopdir" --define "_builddir $(pwd)/$pkg" \
        --define "_rpmdir $rpmtopdir/BUILDRPMS" --define "_sourcedir $(pwd)" $pkg.spec
    cd ..
    # install devel rpms for next round of dependencies
    yum -y install BUILDRPMS/*/*.rpm
    # move runtime rpms to runtime dir
    if [ ! -d /RPMS ] ; then
        mkdir -p /RPMS
    fi
    find BUILDRPMS -type f -print | while read rpmfile ; do
        case $rpmfile in
        ${pkg}-devel-*.rpm) continue ;;
        ${pkg}-doc-*.rpm) continue ;;
        *.src.rpm) continue ;;
        *) mv $rpmfile /RPMS/ ;;
        esac
    done
    rm -rf BUILDRPMS/*
done
sort $contents > /contents

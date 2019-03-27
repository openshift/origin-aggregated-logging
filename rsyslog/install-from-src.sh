#!/bin/bash

set -euxo pipefail

# must be listed in dependency order
packages="librelp libestr libfastjson liblognorm librdkafka rsyslog"

rpmtopdir=$( pwd )
for pkg in $packages ; do
    cd $pkg
    # SourceN and PatchN should already have been removed from the spec file
    # remove %prep section from rpm spec
    sed -e '/^%prep/,/^%build/{/^%build/!d}' -i $pkg.spec
    # put RPMS in ../RPMS - use source code from $pkg dir and build in that dir as well
    rpmbuild -bb --define "_topdir $rpmtopdir" --define "_builddir $(pwd)/$pkg" --define "_sourcedir $(pwd)" $pkg.spec
    cd ..
    # install rpms for next round of dependencies
    yum -y install RPMS/*/*.rpm
done

# remove all RPM files except those needed at runtime
for pkg in $packages ; do
    find RPMS -name ${pkg}-devel-\*.rpm -exec rm -f {} /dev/null \;
    find RPMS -name ${pkg}-doc-\*.rpm -exec rm -f {} /dev/null \;
    find RPMS -name \*.src.rpm -exec rm -f {} /dev/null \;
done
#ls -alrRtF RPMS

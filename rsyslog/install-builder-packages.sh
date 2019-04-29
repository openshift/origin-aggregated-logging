#!/bin/bash

set -euxo pipefail

rhelver=""
if [ -f /etc/redhat-release ] ; then
    rhelver=$( sed 's/^Red Hat Enterprise Linux Server release \([1-9][0-9]*\)[.].*$/\1/' /etc/redhat-release )
fi
# get pkg list from rpmspec -q --buildrequires vendored_src/*/*.spec | sort -u
PKGLIST="make redhat-rpm-config rpm-build \
      autoconf automake bison chrpath cyrus-sasl-devel \
      flex gcc gcc-c++ gnutls-devel krb5-devel libcurl-devel \
      libgcrypt-devel libtool libuuid-devel lz4-devel \
      net-snmp-devel pcre-devel pkgconfig postgresql-devel \
      systemd-devel zlib-devel golang"
if [ "$rhelver" = 7 ] ; then
    PKGLIST="$PKGLIST mariadb-devel python-sphinx"
else
    PKGLIST="$PKGLIST mariadb-connector-c-devel python3 python3-docutils python3-sphinx"
fi
yum -y install $PKGLIST
rpm -V $PKGLIST
yum clean all

#!/bin/bash
#
# This script updates the vendored libraries
# added to Kibana

if [[ -n ${DEBUG:-""} ]] ; then
    set -x
fi

set -o errexit
set -o nounset
set -o pipefail

function help(){
  cat << TXT

This script updates the vendored libraries found in kibana/lib

  use: $0 <RELEASE>

  e.g: $0 v4.5.1-2

TXT
}

vendor_lib=origin-kibana
vendor_release=${1:-""}

if [ -z ${vendor_lib} ] || [ -z ${vendor_release} ] ; then
    help
    exit 1
fi

libdir="$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)/../kibana/lib/${vendor_lib}"


DOWNLOAD_URL=${DOWNLOAD_URL:-https://github.com/openshift/origin-kibana/releases/download/${vendor_release}/origin-kibana-${vendor_release}.tgz}

rm -rf $libdir
mkdir $libdir
pushd $libdir
  wget -q $DOWNLOAD_URL -O _release_
  file _release_
  tar -xf _release_
  rm _release_
popd


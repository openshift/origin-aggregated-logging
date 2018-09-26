#!/bin/bash

set -euxo pipefail

SOURCE_GEM_DIR=${SOURCE_GEM_DIR:-/}

for gem in ${SOURCE_GEM_DIR:-}*.gem ; do
    gem unpack $gem
    gem_name_ver=$( basename $gem .gem )
    gem_name=$( gem spec $gem | awk '/^name: / {print $2}' )
    pushd $gem_name_ver
    for file in ../$gem_name_ver.*.source.patch ; do
        if [ -f "$file" ] ; then
            patch -p1 < $file
        fi
    done
    if [ -f ../$gem_name_ver.sources.patch.sh ] ; then
        ../$gem_name_ver.sources.patch.sh
    fi
    gem spec $gem -l --ruby > $gem_name.gemspec
    for file in ../$gem_name_ver.*.gemspec.patch ; do
        if [ -f "$file" ] ; then
            patch -p1 < $file
        fi
    done
    if [ -f ../$gem_name_ver.gemspec.patch.sh ] ; then
        ../$gem_name_ver.gemspec.patch.sh $gem_name.gemspec
    fi
    gem build $gem_name.gemspec
    if [ -f ../$gem ] ; then
        mv ../$gem ../$gem.orig
    fi
    mv $gem ..
    popd
done

CONFIGURE_ARGS="--with-cflags='$( rpm --eval %optflags )' ${CONFIGURE_ARGS:-}" \
              gem install -V --local -N *.gem

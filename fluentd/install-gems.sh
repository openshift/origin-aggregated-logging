#!/bin/bash

set -euo pipefail

# patch files should be of the form
# $gem_name.sourceNNNN.patch
# e.g. ffi.source0001.patch
# same with gemspec patches
# $gem_name.gemspecNNNN.patch
# this allows for 9999 patches, and ensures
# that patches are applied in order

gem --version

contents=$( mktemp )
trap "rm -f $contents" EXIT

for dir in * ; do
    if [ ! -f $dir/$dir.gemspec ] ; then
        echo directory $dir has no gemspec - assuming not a gem dir - skipping
        continue
    fi
    pushd $dir > /dev/null
    gem_name=$dir
    for file in ../$gem_name.source????.patch ; do
        if [ -f "$file" ] ; then
            patch -p1 < $file
        fi
    done
    if [ -f ../$gem_name.sources.patch.sh ] ; then
        ../$gem_name.sources.patch.sh
    fi
    for file in ../$gem_name.gemspec????.patch ; do
        if [ -f "$file" ] ; then
            patch -p1 < $file
        fi
    done
    if [ -f ../$gem_name.gemspec.patch.sh ] ; then
        ../$gem_name.gemspec.patch.sh $gem_name.gemspec
    fi
    # ugh - many gemspecs use `git ls-files` to get the
    # list of sources - so actually create a brand new
    # git repo here so that git ls-files will work - no,
    # it isn't really possible to write a script to
    # replicate git ls-files - too many options :-(
    if grep -q 'git.*ls-files' $gem_name.gemspec ; then
        git init -q
        git add $( ls -A )
    fi
    gem build $gem_name.gemspec || {
        cat $gem_name.gemspec
        gem build -V $gem_name.gemspec
        exit 1
    }
    gem_ver=$( gem spec --ruby *.gem | ruby -e 'gemspec=eval($stdin.read); puts gemspec.version.version' )
    echo $gem_name $gem_ver >> $contents
    mv *.gem ..
    popd > /dev/null
done

if CONFIGURE_ARGS="--with-cflags='$( rpm --eval %optflags )' ${CONFIGURE_ARGS:-}" \
   gem install -V --local -N *.gem ; then
   echo INFO: all gems installed successfully
   rc=0
else
    echo ERROR: some gems not installed successfully
    for dir in * ; do
        if [ ! -f $dir/$dir.gemspec ] ; then
            continue
        fi
        if ! gem contents --silent $dir ; then
            echo ERROR: gem $dir not installed
            CONFIGURE_ARGS="--with-cflags='$( rpm --eval %optflags )' ${CONFIGURE_ARGS:-}" \
                gem install -V --local -N $dir-*.gem || :
        fi
    done
    rc=1
fi
sort $contents >> /contents
exit $rc

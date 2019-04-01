#!/bin/bash
# Update the vendored-in fluentd gems
# - get the latest fluentd gem and latest dependencies
# - unpack the gems into the fluentd/vendor directory
# - update the fluentd/manifest file with the new gems

set -euxo pipefail

basedir=$( dirname $0 )
if [ -z "$basedir" ] ; then
    pushd .. > /dev/null
    basedir=$( pwd )
    popd
else
    pushd $basedir/.. > /dev/null
    basedir=$( pwd )
    popd > /dev/null
fi

fluentddir=$basedir/fluentd

gemlist=$( mktemp )
sources=$( mktemp )
# the format of gem install --explain is
# name-of-gem-file-X.Y.Z - we assume everything
# after the last '-' is the version, and split
# the output into name version
gem install --explain -g $fluentddir/Gemfile | \
sed -e '/^Gems/d' -e 's,[-]\([^-][^-]*\)$, \1,' > $gemlist
while read gemname gemver ; do
    vendordir=$fluentddir/vendored_gem_src/$gemname
    gemfile=${gemname}-${gemver}.gem
    gemlink=$fluentddir/vendored_gem_src/${gemname}-${gemver}
    gem fetch $gemname --version $gemver
    md5sum $gemfile >> $sources
    rm -rf $vendordir
    mkdir -p $vendordir
    # gem unpack always creates $gemname-$gemver
    # but we want to unpack in $gemname
    # so create a symlink to fool unpack
    rm -f $gemlink
    ln -s $vendordir $gemlink
    gem unpack $gemfile --target $fluentddir/vendored_gem_src
    # the .gitignore files cause no end of trouble
    # - the files in the gem should not be ignored, but in
    #   _many_ cases, files are listed both in the gem _and_
    #   in the .gitignore
    # - many gemspecs use `git ls-files` to get the list of
    #   files to include in the gem - the .gitignore in many
    #   cases will exclude files which should be in the gem
    find $vendordir -name .gitignore -exec rm -f {} \;
    # some gems do not include the gemspec in the data, so unpack
    # won't see it - but we need the gemspec for gem build later
    if [ ! -f $vendordir/$gemname.gemspec ] ; then
        gem spec -l --ruby $gemfile > $vendordir/$gemname.gemspec
    fi
    rm -f $gemlink $gemfile
done < $gemlist
rm -f $gemlist
# update fluentd manifest
sort -k 2 $sources > $fluentddir/manifest
rm -f $sources

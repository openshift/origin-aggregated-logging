# added 2014-11-14 by singh.janmejay
# This file is part of the liblognorm project, released under ASL 2.0

uname -a | grep "SunOS.*5.10"
if [ $? -eq 0 ] ; then
   echo platform: `uname -a`
   echo This looks like solaris 10, we disable known-failing tests to
   echo permit OpenCSW to build packages. However, this are real failurs
   echo and so a fix should be done as soon as time permits.
   exit 77
fi
export ln_opts='-oallowRegex'
. $srcdir/exec.sh

test_def $0 "type ERE for regex field"
add_rule 'rule=:%first:regex:[a-z]+% %second:regex:\d+\x25\x3a[a-f0-9]+\x25%'
execute 'foo 122%:7a%'
assert_output_contains '"first": "foo"'
assert_output_contains '"second": "122%:7a%"'



cleanup_tmp_files


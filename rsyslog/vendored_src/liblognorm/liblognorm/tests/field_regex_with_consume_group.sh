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

test_def $0 "regex field with consume-group"
add_rule 'rule=:%first:regex:([a-z]{2}([a-f0-9]+,)+):0%%rest:rest%'
execute 'ad1234abcd,4567ef12,8901abef'
assert_output_contains '"first": "ad1234abcd,4567ef12,"'
assert_output_contains '"rest": "8901abef"'
reset_rules
add_rule 'rule=:%first:regex:(([a-z]{2})([a-f0-9]+,)+):2%%rest:rest%'
execute 'ad1234abcd,4567ef12,8901abef'
assert_output_contains '"first": "ad"'
assert_output_contains '"rest": "1234abcd,4567ef12,8901abef"'



cleanup_tmp_files


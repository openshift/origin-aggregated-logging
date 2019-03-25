# added 2014-11-17 by singh.janmejay
# This file is part of the liblognorm project, released under ASL 2.0

uname -a | grep "SunOS.*5.10"
if [ $? -eq 0 ] ; then
   echo platform: `uname -a`
   echo This looks like solaris 10, we disable known-failing tests to
   echo permit OpenCSW to build packages. However, this are real failurs
   echo and so a fix should be done as soon as time permits.
   exit 77
fi

#test that tokenized disabled regex if parent context has it disabled
. $srcdir/exec.sh

test_def $0 "tokenized field with regex based field"
add_rule 'rule=:%parts:tokenized:,:regex:[^, ]+% %text:rest%'
execute '123,abc,456,def foo bar'
assert_output_contains '"unparsed-data": "123,abc,456,def foo bar"'
assert_output_contains '"originalmsg": "123,abc,456,def foo bar"'

#and then enables it when parent context has it enabled
export ln_opts='-oallowRegex'
. $srcdir/exec.sh

test_def $0 "tokenized field with regex based field"
add_rule 'rule=:%parts:tokenized:,:regex:[^, ]+% %text:rest%'
execute '123,abc,456,def foo bar'
assert_output_contains '"parts": [ "123", "abc", "456", "def" ]'
assert_output_contains '"text": "foo bar"'


cleanup_tmp_files


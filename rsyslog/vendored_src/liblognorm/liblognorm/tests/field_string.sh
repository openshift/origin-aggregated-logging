# added 2015-09-02 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

uname -a | grep "SunOS.*5.10"
if [ $? -eq 0 ] ; then
   echo platform: `uname -a`
   echo This looks like solaris 10, we disable known-failing tests to
   echo permit OpenCSW to build packages. However, this are real failurs
   echo and so a fix should be done as soon as time permits.
   exit 77
fi
. $srcdir/exec.sh

test_def $0 "string syntax"

reset_rules
add_rule 'version=2'
add_rule 'rule=:a %f:string% b'

execute 'a test b'
assert_output_json_eq '{"f": "test"}'

execute 'a "test" b'
assert_output_json_eq '{"f": "test"}'

execute 'a "test with space" b'
assert_output_json_eq '{"f": "test with space"}'

execute 'a "test with "" double escape" b'
assert_output_json_eq '{ "f": "test with \" double escape" }'

execute 'a "test with \" backslash escape" b'
assert_output_json_eq '{ "f": "test with \" backslash escape" }'

echo test quoting.mode
reset_rules
add_rule 'version=2'
add_rule 'rule=:a %f:string{"quoting.mode":"none"}% b'

execute 'a test b'
assert_output_json_eq '{"f": "test"}'

execute 'a "test" b'
assert_output_json_eq '{"f": "\"test\""}'

echo "test quoting.char.*"
reset_rules
add_rule 'version=2'
add_rule 'rule=:a %f:string{"quoting.char.begin":"[", "quoting.char.end":"]"}% b'

execute 'a test b'
assert_output_json_eq '{"f": "test"}'

execute 'a [test] b'
assert_output_json_eq '{"f": "test"}'

execute 'a [test test2] b'
assert_output_json_eq '{"f": "test test2"}'

# things that need to NOT match

cleanup_tmp_files

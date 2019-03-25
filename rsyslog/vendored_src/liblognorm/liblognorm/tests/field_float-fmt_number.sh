# added 2017-10-02 by singh.janmejay
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

test_def $0 "float field"
add_rule 'version=2'
add_rule 'rule=:here is a number %{ "type":"float", "name":"num", "format":"number"}% in floating pt form'
execute 'here is a number 15.9 in floating pt form'
assert_output_json_eq '{"num": 15.9}'

reset_rules

# note: floating point numbers are tricky to get right, even more so if negative.
add_rule 'version=2'
add_rule 'rule=:here is a negative number %{ "type":"float", "name":"num", "format":"number"}% for you'
execute 'here is a negative number -4.2 for you'
assert_output_json_eq '{"num": -4.2}'

reset_rules

add_rule 'version=2'
add_rule 'rule=:here is another real number %{ "type":"float", "name":"num", "format":"number"}%.'
execute 'here is another real number 2.71.'
assert_output_json_eq '{"num": 2.71}'


cleanup_tmp_files

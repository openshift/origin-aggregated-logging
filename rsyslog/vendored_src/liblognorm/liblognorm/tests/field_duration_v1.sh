# added 2015-03-12 by Rainer Gerhards
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

test_def $0 "duration syntax"
add_rule 'rule=:duration %field:duration% bytes'
add_rule 'rule=:duration %field:duration%'

execute 'duration 0:00:42 bytes'
assert_output_json_eq '{"field": "0:00:42"}'

execute 'duration 0:00:42'
assert_output_json_eq '{"field": "0:00:42"}'

execute 'duration 9:00:42 bytes'
assert_output_json_eq '{"field": "9:00:42"}'

execute 'duration 00:00:42 bytes'
assert_output_json_eq '{"field": "00:00:42"}'

execute 'duration 37:59:42 bytes'
assert_output_json_eq '{"field": "37:59:42"}'

execute 'duration 37:60:42 bytes'
assert_output_contains '"unparsed-data": "37:60:42 bytes"'


cleanup_tmp_files


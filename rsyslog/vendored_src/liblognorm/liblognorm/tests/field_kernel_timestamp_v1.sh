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

test_def $0 "kernel timestamp parser"
add_rule 'rule=:begin %timestamp:kernel-timestamp% end'
execute 'begin [12345.123456] end'
assert_output_json_eq '{ "timestamp": "[12345.123456]"}'

reset_rules

add_rule 'rule=:begin %timestamp:kernel-timestamp%'
execute 'begin [12345.123456]'
assert_output_json_eq '{ "timestamp": "[12345.123456]"}'

reset_rules

add_rule 'rule=:%timestamp:kernel-timestamp%'
execute '[12345.123456]'
assert_output_json_eq '{ "timestamp": "[12345.123456]"}'

execute '[154469.133028]'
assert_output_json_eq '{ "timestamp": "[154469.133028]"}'

execute '[123456789012.123456]'
assert_output_json_eq '{ "timestamp": "[123456789012.123456]"}'

#check cases where parsing failure must occur
execute '[1234.123456]'
assert_output_json_eq '{"originalmsg": "[1234.123456]", "unparsed-data": "[1234.123456]" }'

execute '[1234567890123.123456]'
assert_output_json_eq '{"originalmsg": "[1234567890123.123456]", "unparsed-data": "[1234567890123.123456]" }'

execute '[123456789012.12345]'
assert_output_json_eq '{ "originalmsg": "[123456789012.12345]", "unparsed-data": "[123456789012.12345]" }'

execute '[123456789012.1234567]'
assert_output_json_eq '{ "originalmsg": "[123456789012.1234567]", "unparsed-data": "[123456789012.1234567]" }'

execute '(123456789012.123456]'
assert_output_json_eq '{ "originalmsg": "(123456789012.123456]", "unparsed-data": "(123456789012.123456]" }'

execute '[123456789012.123456'
assert_output_json_eq '{ "originalmsg": "[123456789012.123456", "unparsed-data": "[123456789012.123456" }'


cleanup_tmp_files


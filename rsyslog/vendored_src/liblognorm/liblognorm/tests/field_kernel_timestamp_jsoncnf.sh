# added 2015-03-12 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "kernel timestamp parser"
add_rule 'version=2'
add_rule 'rule=:begin %{"name":"timestamp", "type":"kernel-timestamp"}% end'
execute 'begin [12345.123456] end'
assert_output_json_eq '{ "timestamp": "[12345.123456]"}'

reset_rules

add_rule 'version=2'
add_rule 'rule=:begin %{"name":"timestamp", "type":"kernel-timestamp"}%'
execute 'begin [12345.123456]'
assert_output_json_eq '{ "timestamp": "[12345.123456]"}'

reset_rules

add_rule 'version=2'
add_rule 'rule=:%{"name":"timestamp", "type":"kernel-timestamp"}%'
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


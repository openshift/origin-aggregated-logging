# added 2015-03-12 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "duration syntax"
add_rule 'version=2'
add_rule 'rule=:duration %{"name":"field", "type":"duration"}% bytes'
add_rule 'rule=:duration %{"name":"field", "type":"duration"}%'

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


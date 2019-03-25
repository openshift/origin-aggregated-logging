# added 2015-03-01 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "JSON field"
add_rule 'version=2'
add_rule 'rule=:%field:json%'

execute '{"f1": "1", "f2": 2}'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'

# let's see if something more complicated still works, so ADD some
# more rules
add_rule 'rule=:begin %field:json%'
add_rule 'rule=:begin %field:json%end'
add_rule 'rule=:%field:json%end'

execute '{"f1": "1", "f2": 2}'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'
#check if trailinge whitspace is ignored
execute '{"f1": "1", "f2": 2}      '
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'

execute 'begin {"f1": "1", "f2": 2}'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'

execute 'begin {"f1": "1", "f2": 2}end'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'
# note: the parser takes all whitespace after the JSON
# to be part of it!
execute 'begin {"f1": "1", "f2": 2} end'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'
execute 'begin {"f1": "1", "f2": 2} 	     end'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'

execute '{"f1": "1", "f2": 2}end'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'

#check cases where parsing failure must occur
execute '{"f1": "1", f2: 2}'
assert_output_json_eq '{ "originalmsg": "{\"f1\": \"1\", f2: 2}", "unparsed-data": "{\"f1\": \"1\", f2: 2}" }'

#some more complex cases
add_rule 'rule=:%field1:json%-%field2:json%'

execute '{"f1": "1"}-{"f2": 2}'
assert_output_json_eq '{ "field2": { "f2": 2 }, "field1": { "f1": "1" } }'

# re-check previsous def still works
execute '{"f1": "1", "f2": 2}'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'

# now check some strange cases
reset_rules
add_rule 'version=2'
add_rule 'rule=:%field:json%'

# this check is because of bug in json-c:
# https://github.com/json-c/json-c/issues/181
execute '15:00'
assert_output_json_eq '{ "originalmsg": "15:00", "unparsed-data": "15:00" }'


cleanup_tmp_files


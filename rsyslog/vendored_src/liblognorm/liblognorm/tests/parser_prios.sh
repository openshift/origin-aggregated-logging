# added 2015-05-05 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "parser priorities, simple case"
add_rule 'version=2'
add_rule 'rule=:%{"name":"field", "type":"mac48"}%'
add_rule 'rule=:%{"name":"rest", "type":"rest"}%'

execute 'f0:f6:1c:5f:cc:a2'
assert_output_json_eq '{"field": "f0:f6:1c:5f:cc:a2"}'

execute 'f0-f6-1c-5f-cc-a2'
assert_output_json_eq '{"field": "f0-f6-1c-5f-cc-a2"}'

# things that need to match rest

execute 'f0-f6:1c:5f:cc-a2'
assert_output_json_eq '{ "rest": "f0-f6:1c:5f:cc-a2" }'


# now the same with inverted priorites. We should now always have
# rest matches.
reset_rules
add_rule 'version=2'
add_rule 'rule=:%{"name":"field", "type":"mac48", "priority":100}%'
add_rule 'rule=:%{"name":"rest", "type":"rest", "priority":10}%'

execute 'f0:f6:1c:5f:cc:a2'
assert_output_json_eq '{"rest": "f0:f6:1c:5f:cc:a2"}'

execute 'f0-f6-1c-5f-cc-a2'
assert_output_json_eq '{"rest": "f0-f6-1c-5f-cc-a2"}'

execute 'f0-f6:1c:5f:cc-a2'
assert_output_json_eq '{ "rest": "f0-f6:1c:5f:cc-a2" }'

cleanup_tmp_files

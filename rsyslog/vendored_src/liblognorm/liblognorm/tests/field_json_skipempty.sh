# added 2018-08-27 by Noriko Hosoi
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "JSON field"
add_rule 'version=2'
add_rule 'rule=:%field:json%'

# default behaviour
execute '{"f1": "1", "f2": 2, "f3": "", "f4": {}, "f5": []}'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 , "f3": "", "f4": {}, "f5": []} }'

# skip empty json values
reset_rules
add_rule 'version=2'
add_rule 'rule=:%field:json:skipempty%'

execute '{"f1": "1", "f2": 2, "f3": "", "f4": {}, "f5": []}'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'

# undefined parameter has to be ignored?
reset_rules
add_rule 'version=2'
add_rule 'rule=:%field:json:bogus%'

execute '{"f1": "1", "f2": 2, "f3": "", "f4": {}, "f5": []}'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 , "f3": "", "f4": {}, "f5": []} }'

cleanup_tmp_files


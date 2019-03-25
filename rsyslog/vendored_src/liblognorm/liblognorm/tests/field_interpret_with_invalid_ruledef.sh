# added 2014-12-11 by singh.janmejay
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "value interpreting field, with invalid ruledef"

add_rule 'rule=:%session_count:interpret:int:wd% sessions established'
execute '64 sessions established'
assert_output_json_eq '{ "originalmsg": "64 sessions established", "unparsed-data": "64 sessions established" }'

reset_rules
add_rule 'rule=:%session_count:interpret:int:% sessions established'
execute '64 sessions established'
assert_output_json_eq '{ "originalmsg": "64 sessions established", "unparsed-data": "64 sessions established" }'

reset_rules
add_rule 'rule=:%session_count:interpret:int% sessions established'
execute '64 sessions established'
assert_output_json_eq '{ "originalmsg": "64 sessions established", "unparsed-data": "64 sessions established" }'

reset_rules
add_rule 'rule=:%session_count:interpret:in% sessions established'
execute '64 sessions established'
assert_output_json_eq '{ "originalmsg": "64 sessions established", "unparsed-data": "64 sessions established" }'

reset_rules
add_rule 'rule=:%session_count:interpret:in:word% sessions established'
execute '64 sessions established'
assert_output_json_eq '{ "originalmsg": "64 sessions established", "unparsed-data": "64 sessions established" }'

reset_rules
add_rule 'rule=:%session_count:interpret:in:wd% sessions established'
execute '64 sessions established'
assert_output_json_eq '{ "originalmsg": "64 sessions established", "unparsed-data": "64 sessions established" }'

reset_rules
add_rule 'rule=:%session_count:interpret::word% sessions established'
execute '64 sessions established'
assert_output_json_eq '{ "originalmsg": "64 sessions established", "unparsed-data": "64 sessions established" }'

reset_rules
add_rule 'rule=:%session_count:interpret::% sessions established'
execute '64 sessions established'
assert_output_json_eq '{ "originalmsg": "64 sessions established", "unparsed-data": "64 sessions established" }'

reset_rules
add_rule 'rule=:%session_count:inter::% sessions established'
execute '64 sessions established'
assert_output_json_eq '{ "originalmsg": "64 sessions established", "unparsed-data": "64 sessions established" }'

reset_rules
add_rule 'rule=:%session_count:inter:int:word% sessions established'
execute '64 sessions established'
assert_output_json_eq '{ "originalmsg": "64 sessions established", "unparsed-data": "64 sessions established" }'



cleanup_tmp_files


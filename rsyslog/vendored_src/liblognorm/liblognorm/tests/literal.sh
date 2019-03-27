# added 2016-12-21 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh
test_def $0 "using names with literal"

add_rule 'version=2'
add_rule 'rule=:%{"type":"literal", "text":"a", "name":"var"}%'
execute 'a'
assert_output_json_eq '{ "var": "a" }'

reset_rules
add_rule 'version=2'
add_rule 'rule=:Test %{"type":"literal", "text":"a", "name":"var"}%'
execute 'Test a'
assert_output_json_eq '{ "var": "a" }'

reset_rules
add_rule 'version=2'
add_rule 'rule=:Test %{"type":"literal", "text":"a", "name":"var"}% End'
execute 'Test a End'
assert_output_json_eq '{ "var": "a" }'

reset_rules
add_rule 'version=2'
add_rule 'rule=:a %[{"name":"num", "type":"number"}, {"name":"colon", "type":"literal", "text":":"}, {"name":"hex", "type":"hexnumber"}]% b'
execute 'a 4711:0x4712 b'
assert_output_json_eq '{ "hex": "0x4712", "colon": ":", "num": "4711" }'

cleanup_tmp_files

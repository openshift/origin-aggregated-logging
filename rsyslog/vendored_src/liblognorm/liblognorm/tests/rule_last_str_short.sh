. $srcdir/exec.sh

test_def $0 "string being last in a rule (see also: rule_last_str_long.sh)"

add_rule 'version=2'
add_rule 'rule=:%string:string%'

execute 'string'

assert_output_json_eq '{"string": "string" }'


cleanup_tmp_files

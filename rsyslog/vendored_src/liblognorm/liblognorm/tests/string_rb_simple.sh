# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "simple rulebase via string"
execute_with_string 'rule=:%w:word%' 'test'
assert_output_json_eq '{ "w": "test" }'

cleanup_tmp_files

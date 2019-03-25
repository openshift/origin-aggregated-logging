# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "simple rulebase via string"
execute_with_string 'rule=:%w:word%
rule=:%n:number%' 'test'
assert_output_json_eq '{ "w": "test" }'

execute_with_string 'rule=:%w:word%
rule=:%n:number%' '2'
assert_output_json_eq '{ "n": "2" }'

#This is a correct word...
execute_with_string 'rule=:%w:word%
rule=:%n:number%' '2.3'
assert_output_json_eq '{ "w": "2.3" }'

#check error case
execute_with_string 'rule=:%w:word%
rule=:%n:number%' '2 3'
assert_output_json_eq '{ "originalmsg": "2 3", "unparsed-data": " 3" }'

cleanup_tmp_files

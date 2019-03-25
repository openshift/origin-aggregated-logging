# added 2015-03-01 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "hexnumber field with range checks"
add_rule 'version=2'
add_rule 'rule=:here is a number %num:hexnumber{"maxval":191}% in hex form'
execute 'here is a number 0x12 in hex form'
assert_output_json_eq '{"num": "0x12"}'
execute 'here is a number 0x0 in hex form'
assert_output_json_eq '{"num": "0x0"}'
execute 'here is a number 0xBf in hex form'
assert_output_json_eq '{"num": "0xBf"}'

#check cases where parsing failure must occur
execute 'here is a number 0xc0 in hex form'
assert_output_json_eq '{ "originalmsg": "here is a number 0xc0 in hex form", "unparsed-data": "0xc0 in hex form" }'


cleanup_tmp_files


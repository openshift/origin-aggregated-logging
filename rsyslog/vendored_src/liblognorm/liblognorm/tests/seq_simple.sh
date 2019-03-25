# added 2015-07-22 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "simple sequence (array) syntax"
add_rule 'version=2'
add_rule 'rule=:a %[{"name":"num", "type":"number"}, {"name":"-", "type":"literal", "text":":"}, {"name":"hex", "type":"hexnumber"}]% b'
execute 'a 4711:0x4712 b'
assert_output_json_eq '{ "hex": "0x4712", "num": "4711" }'

cleanup_tmp_files

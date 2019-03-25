# added 2015-07-22 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "simple alternative syntax"
add_rule 'version=2'
add_rule 'rule=:a %{"type":"alternative", "parser":[{"name":"num", "type":"number"}, {"name":"hex", "type":"hexnumber"}]}% b'
execute 'a 4711 b'
assert_output_json_eq '{ "num": "4711" }'
execute 'a 0x4711 b'
assert_output_json_eq '{ "hex": "0x4711" }'

cleanup_tmp_files

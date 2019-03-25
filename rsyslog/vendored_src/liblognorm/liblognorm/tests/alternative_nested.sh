# added 2015-07-22 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "simple alternative syntax"
add_rule 'version=2'
add_rule 'rule=:a %
            {"type":"alternative",
	     "parser": [
	                [
			  {"type":"number", "name":"num1"},
			  {"type":"literal", "text":":"},
			  {"type":"number", "name":"num"},
			],
			{"type":"hexnumber", "name":"hex"}
		       ]
	    }% b'
execute 'a 47:11 b'
assert_output_json_eq '{"num": "11", "num1": "47" }'
execute 'a 0x4711 b'
assert_output_json_eq '{ "hex": "0x4711" }'

cleanup_tmp_files

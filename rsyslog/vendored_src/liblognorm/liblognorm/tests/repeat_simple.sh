# added 2015-07-22 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "simple repeat syntax"
add_rule 'version=2'
add_rule 'rule=:a %{"name":"numbers", "type":"repeat",
			"parser":[
			  {"name":"n1", "type":"number"},
			  {"type":"literal", "text":":"},
			  {"name":"n2", "type":"number"}
			  ],
			"while":[
			  {"type":"literal", "text":", "}
			]
       		   }% b %w:word%
'
execute 'a 1:2, 3:4, 5:6, 7:8 b test'
assert_output_json_eq '{ "w": "test", "numbers": [ { "n2": "2", "n1": "1" }, { "n2": "4", "n1": "3" }, { "n2": "6", "n1": "5" }, { "n2": "8", "n1": "7" } ] }'

cleanup_tmp_files

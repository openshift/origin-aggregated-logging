# added 2015-07-22 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "very simple repeat syntax"
add_rule 'version=2'
add_rule 'rule=:a %{"name":"numbers", "type":"repeat",
			"parser":
			  {"name":"n", "type":"number"},
			"while":
			  {"type":"literal", "text":", "}
       		   }% b %w:word%
'
execute 'a 1, 2, 3, 4 b test'
assert_output_json_eq '{ "w": "test", "numbers": [ { "n": "1" }, { "n": "2" }, { "n": "3" }, { "n": "4" } ] }'

cleanup_tmp_files

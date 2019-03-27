# added 2015-07-22 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "simple alternative syntax"
add_rule 'version=2'
add_rule 'rule=:a %{"name":"numbers", "type":"repeat",
			"parser":
                            { "type":"alternative", "parser": [
	                           [ {"type":"number", "name":"n1"},
			             {"type":"literal", "text":":"},
		              	     {"type":"number", "name":"n2"},
		              	   ],
		              	   {"type":"hexnumber", "name":"hex"}
		               ]
			    },
			"while":[
			  {"type":"literal", "text":", "}
			]
       		   }% b'

execute 'a 1:2, 3:4, 5:6, 7:8 b'
assert_output_json_eq '{ "numbers": [ { "n2": "2", "n1": "1" }, { "n2": "4", "n1": "3" }, { "n2": "6", "n1": "5" }, { "n2": "8", "n1": "7" } ] }'

execute 'a 0x4711 b'
assert_output_json_eq '{ "numbers": [ { "hex": "0x4711" } ] }'

# note: 0x4711, 1:2 does not work because hexnumber expects a SP after 
# the number! Thus we use the reverse. We could add this case once
# we have added an option for more relaxed matching to hexnumber.
execute 'a 1:2, 0x4711 b'
assert_output_json_eq '{ "numbers": [ { "n2": "2", "n1": "1" }, { "hex": "0x4711" } ] }'

cleanup_tmp_files

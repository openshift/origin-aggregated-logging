# added 2017-10-02 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "hexnumber field"
add_rule 'version=2'
add_rule 'rule=:here is a number %{ "type":"hexnumber", "name":"num", "format":"number"} % in hex form'
execute 'here is a number 0x1234 in hex form'
assert_output_json_eq '{"num": 4660}'

#check cases where parsing failure must occur
execute 'here is a number 0x1234in hex form'
assert_output_json_eq '{ "originalmsg": "here is a number 0x1234in hex form", "unparsed-data": "0x1234in hex form" }'


cleanup_tmp_files


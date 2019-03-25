# added 2017-10-02 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "number field in native format"
add_rule 'version=2'
add_rule 'rule=:here is a number %{ "type":"number", "name":"num", "format":"number"}% in dec form'
execute 'here is a number 1234 in dec form'
assert_output_json_eq '{"num": 1234}'

#check cases where parsing failure must occur
execute 'here is a number 1234in dec form'
assert_output_json_eq '{ "originalmsg": "here is a number 1234in dec form", "unparsed-data": "in dec form" }'


cleanup_tmp_files

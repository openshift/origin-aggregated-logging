# added 2015-05-05 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "dmac48 syntax"
add_rule 'rule=:%field:mac48%'

execute 'f0:f6:1c:5f:cc:a2'
assert_output_json_eq '{"field": "f0:f6:1c:5f:cc:a2"}'

execute 'f0-f6-1c-5f-cc-a2'
assert_output_json_eq '{"field": "f0-f6-1c-5f-cc-a2"}'

# things that need to NOT match

execute 'f0-f6:1c:5f:cc-a2'
assert_output_json_eq '{ "originalmsg": "f0-f6:1c:5f:cc-a2", "unparsed-data": "f0-f6:1c:5f:cc-a2" }'

execute 'f0:f6:1c:xf:cc:a2'
assert_output_json_eq '{ "originalmsg": "f0:f6:1c:xf:cc:a2", "unparsed-data": "f0:f6:1c:xf:cc:a2" }'


cleanup_tmp_files


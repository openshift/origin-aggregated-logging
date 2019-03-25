# added 2015-03-01 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "JSON field"
add_rule 'version=2'
add_rule 'rule=:%{"name":"field", "type":"cee-syslog"}%'

execute '@cee:{"f1": "1", "f2": 2}'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'

execute '@cee:{"f1": "1", "f2": 2} ' # note the trailing space
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'

execute '@cee: {"f1": "1", "f2": 2}'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'

execute '@cee:     {"f1": "1", "f2": 2}'
assert_output_json_eq '{ "field": { "f1": "1", "f2": 2 } }'

#
# Things that MUST NOT work
#
execute '@cee: {"f1": "1", "f2": 2} data'
assert_output_json_eq '{ "originalmsg": "@cee: {\"f1\": \"1\", \"f2\": 2} data", "unparsed-data": "@cee: {\"f1\": \"1\", \"f2\": 2} data" }'


cleanup_tmp_files


# added 2017-10-02 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "RFC5424 timestamp in timestamp-unix format"
add_rule 'version=2'
add_rule 'rule=:here is a timestamp %{ "type":"date-rfc5424", "name":"num", "format":"timestamp-unix"}% in RFC5424 format'
execute 'here is a timestamp 2000-03-11T14:15:16+01:00 in RFC5424 format'
assert_output_json_eq '{"num": 952780516}'

# with milliseconds (must be ignored with this format!)
execute 'here is a timestamp 2000-03-11T14:15:16.321+01:00 in RFC5424 format'
assert_output_json_eq '{"num": 952780516}'

#check cases where parsing failure must occur
execute 'here is a timestamp 2000-03-11T14:15:16+01:00in RFC5424 format'
assert_output_json_eq '{ "originalmsg": "here is a timestamp 2000-03-11T14:15:16+01:00in RFC5424 format", "unparsed-data": "2000-03-11T14:15:16+01:00in RFC5424 format" }'


cleanup_tmp_files

# added 2017-10-02 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "RFC5424 timestamp in timestamp-unix format"
add_rule 'version=2'
add_rule 'rule=:here is a timestamp %{ "type":"date-rfc5424", "name":"num", "format":"timestamp-unix-ms"}% in RFC5424 format'
execute 'here is a timestamp 2000-03-11T14:15:16+01:00 in RFC5424 format'
assert_output_json_eq '{ "num": 952780516000}'

# with milliseconds (too-low precision)
execute 'here is a timestamp 2000-03-11T14:15:16.1+01:00 in RFC5424 format'
assert_output_json_eq '{ "num": 952780516100 }'
execute 'here is a timestamp 2000-03-11T14:15:16.12+01:00 in RFC5424 format'
assert_output_json_eq '{ "num": 952780516120 }'

# with milliseconds (exactly right precision)
execute 'here is a timestamp 2000-03-11T14:15:16.123+01:00 in RFC5424 format'
assert_output_json_eq '{ "num": 952780516123 }'

# with overdone precision
execute 'here is a timestamp 2000-03-11T14:15:16.1234+01:00 in RFC5424 format'
assert_output_json_eq '{ "num": 952780516123 }'
execute 'here is a timestamp 2000-03-11T14:15:16.123456789+01:00 in RFC5424 format'
assert_output_json_eq '{ "num": 952780516123 }'

#check cases where parsing failure must occur
execute 'here is a timestamp 2000-03-11T14:15:16+01:00in RFC5424 format'
assert_output_json_eq '{ "originalmsg": "here is a timestamp 2000-03-11T14:15:16+01:00in RFC5424 format", "unparsed-data": "2000-03-11T14:15:16+01:00in RFC5424 format" }'


cleanup_tmp_files

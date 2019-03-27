# added 2015-06-23 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

add_rule 'version=2'
test_def $0 "IPv6 parser"
add_rule 'rule=:%f:ipv6%'

# examples from RFC4291, sect. 2.2
execute 'ABCD:EF01:2345:6789:ABCD:EF01:2345:6789'
assert_output_json_eq '{ "f": "ABCD:EF01:2345:6789:ABCD:EF01:2345:6789" }'
execute 'ABCD:EF01:2345:6789:abcd:EF01:2345:6789' # mixed hex case
assert_output_json_eq '{ "f": "ABCD:EF01:2345:6789:abcd:EF01:2345:6789" }'
execute '2001:DB8:0:0:8:800:200C:417A'
assert_output_json_eq '{ "f": "2001:DB8:0:0:8:800:200C:417A" }'

execute '0:0:0:0:0:0:0:1'
assert_output_json_eq '{ "f": "0:0:0:0:0:0:0:1" }'

execute '2001:DB8::8:800:200C:417A'
assert_output_json_eq '{ "f": "2001:DB8::8:800:200C:417A" }'
execute 'FF01::101'
assert_output_json_eq '{ "f": "FF01::101" }'
execute '::1'
assert_output_json_eq '{ "f": "::1" }'
execute '::'
assert_output_json_eq '{ "f": "::" }'

execute '0:0:0:0:0:0:13.1.68.3'
assert_output_json_eq '{ "f": "0:0:0:0:0:0:13.1.68.3" }'
execute '::13.1.68.3'
assert_output_json_eq '{ "f": "::13.1.68.3" }'
execute '::FFFF:129.144.52.38'
assert_output_json_eq '{ "f": "::FFFF:129.144.52.38" }'

# invalid samples
execute '2001:DB8::8::800:200C:417A' # two :: sequences
assert_output_json_eq '{ "originalmsg": "2001:DB8::8::800:200C:417A", "unparsed-data": "2001:DB8::8::800:200C:417A" }'

execute 'ABCD:EF01:2345:6789:ABCD:EF01:2345::6789' # :: with too many blocks
assert_output_json_eq '{ "originalmsg": "ABCD:EF01:2345:6789:ABCD:EF01:2345::6789", "unparsed-data": "ABCD:EF01:2345:6789:ABCD:EF01:2345::6789" }'

execute 'ABCD:EF01:2345:6789:ABCD:EF01:2345:1:6798' # too many blocks (9)
assert_output_json_eq '{"originalmsg": "ABCD:EF01:2345:6789:ABCD:EF01:2345:1:6798", "unparsed-data": "ABCD:EF01:2345:6789:ABCD:EF01:2345:1:6798" }'

execute ':0:0:0:0:0:0:1' # missing first digit
assert_output_json_eq '{ "originalmsg": ":0:0:0:0:0:0:1", "unparsed-data": ":0:0:0:0:0:0:1" }'

execute '0:0:0:0:0:0:0:' # missing last digit
assert_output_json_eq '{ "originalmsg": "0:0:0:0:0:0:0:", "unparsed-data": "0:0:0:0:0:0:0:" }'

execute '13.1.68.3' # pure IPv4 address
assert_output_json_eq '{ "originalmsg": "13.1.68.3", "unparsed-data": "13.1.68.3" }'


cleanup_tmp_files


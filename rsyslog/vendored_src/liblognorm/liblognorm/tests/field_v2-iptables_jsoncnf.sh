# added 2015-04-30 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "v2-iptables field"
add_rule 'version=2'
add_rule 'rule=:iptables output denied: %{"name":"field", "type":"v2-iptables"}%'

# first, a real-world case
execute 'iptables output denied: IN= OUT=eth0 SRC=176.9.56.141 DST=168.192.14.3 LEN=32 TOS=0x00 PREC=0x00 TTL=64 ID=39110 DF PROTO=UDP SPT=49564 DPT=2010 LEN=12'
assert_output_json_eq '{ "field": { "IN": "", "OUT": "eth0", "SRC": "176.9.56.141", "DST": "168.192.14.3", "LEN": "12", "TOS": "0x00", "PREC": "0x00", "TTL": "64", "ID": "39110", "DF": null, "PROTO": "UDP", "SPT": "49564", "DPT": "2010" } }'

# now some more "fabricated" cases for better readable test
reset_rules
add_rule 'version=2'
add_rule 'rule=:iptables: %field:v2-iptables%'

execute 'iptables: IN=value SECOND=test'
assert_output_json_eq '{ "field": { "IN": "value", "SECOND": "test" }} }'

execute 'iptables: IN= SECOND=test'
assert_output_json_eq '{ "field": { "IN": ""} }'

execute 'iptables: IN SECOND=test'
assert_output_json_eq '{ "field": { "IN": null} }'

execute 'iptables: IN=invalue OUT=outvalue'
assert_output_json_eq '{ "field": { "IN": "invalue", "OUT": "outvalue" } }'

execute 'iptables: IN= OUT=outvalue'
assert_output_json_eq '{ "field": { "IN": "", "OUT": "outvalue" } }'

execute 'iptables: IN OUT=outvalue'
assert_output_json_eq '{ "field": { "IN": null, "OUT": "outvalue" } }'

#
#check cases where parsing failure must occur
#
echo verify failure cases

# lower case is not permitted
execute 'iptables: in=value'
assert_output_json_eq '{ "originalmsg": "iptables: in=value", "unparsed-data": "in=value" }'

execute 'iptables: in='
assert_output_json_eq '{ "originalmsg": "iptables: in=", "unparsed-data": "in=" }'

execute 'iptables: in'
assert_output_json_eq '{ "originalmsg": "iptables: in", "unparsed-data": "in" }'

execute 'iptables: IN' # single field is NOT permitted!
assert_output_json_eq '{ "originalmsg": "iptables: IN", "unparsed-data": "IN" }'

# multiple spaces between n=v pairs are not permitted
execute 'iptables: IN=invalue  OUT=outvalue'
assert_output_json_eq '{ "originalmsg": "iptables: IN=invalue  OUT=outvalue", "unparsed-data": "IN=invalue  OUT=outvalue" }'

execute 'iptables: IN=  OUT=outvalue'
assert_output_json_eq '{ "originalmsg": "iptables: IN=  OUT=outvalue", "unparsed-data": "IN=  OUT=outvalue" }'

execute 'iptables: IN  OUT=outvalue'
assert_output_json_eq '{ "originalmsg": "iptables: IN  OUT=outvalue", "unparsed-data": "IN  OUT=outvalue" }'


cleanup_tmp_files


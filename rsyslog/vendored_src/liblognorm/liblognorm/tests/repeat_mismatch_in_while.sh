# added 2015-08-26 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
# This is based on a practical support case, see
# https://github.com/rsyslog/liblognorm/issues/130

. $srcdir/exec.sh

test_def $0 "repeat with mismatch in parser part"

reset_rules
add_rule 'version=2'
add_rule 'prefix=%timestamp:date-rfc3164% %hostname:word%'
add_rule 'rule=cisco,fwblock: \x25ASA-6-106015\x3a Deny %proto:word% (no connection) from %source:cisco-interface-spec% to %dest:cisco-interface-spec% flags %flags:repeat{ "parser": {"type":"word", "name":"."}, "while":{"type":"literal", "text":" "} }% on interface %srciface:word%'

echo step 1
execute 'Aug 18 13:18:45 192.168.99.2 %ASA-6-106015: Deny TCP (no connection) from 173.252.88.66/443 to 76.79.249.222/52746 flags RST  on interface outside'
assert_output_json_eq '{ "originalmsg": "Aug 18 13:18:45 192.168.99.2 %ASA-6-106015: Deny TCP (no connection) from 173.252.88.66\/443 to 76.79.249.222\/52746 flags RST  on interface outside", "unparsed-data": "RST  on interface outside" }'

# now check case where we permit a mismatch inside the parser part and still
# accept this as valid. This is needed for some use cases. See github
# issue mentioned above for more details.
# Note: there is something odd with the testbench driver: I cannot use two
# consequtiuve spaces 
reset_rules
add_rule 'version=2'
add_rule 'prefix=%timestamp:date-rfc3164% %hostname:word%'
add_rule 'rule=cisco,fwblock: \x25ASA-6-106015\x3a Deny %proto:word% (no connection) from %source:cisco-interface-spec% to %dest:cisco-interface-spec% flags %flags:repeat{ "option.permitMismatchInParser":true, "parser": {"type":"word", "name":"."}, "while":{"type":"literal", "text":" "} }%\x20  on interface %srciface:word%'

echo step 2
execute 'Aug 18 13:18:45 192.168.99.2 %ASA-6-106015: Deny TCP (no connection) from 173.252.88.66/443 to 76.79.249.222/52746 flags RST  on interface outside'
assert_output_json_eq '{ "srciface": "outside", "flags": [ "RST" ], "dest": { "ip": "76.79.249.222", "port": "52746" }, "source": { "ip": "173.252.88.66", "port": "443" }, "proto": "TCP", "hostname": "192.168.99.2", "timestamp": "Aug 18 13:18:45" }'

echo step 3
execute 'Aug 18 13:18:45 192.168.99.2 %ASA-6-106015: Deny TCP (no connection) from 173.252.88.66/443 to 76.79.249.222/52746 flags RST XST  on interface outside'
assert_output_json_eq '{ "srciface": "outside", "flags": [ "RST", "XST" ], "dest": { "ip": "76.79.249.222", "port": "52746" }, "source": { "ip": "173.252.88.66", "port": "443" }, "proto": "TCP", "hostname": "192.168.99.2", "timestamp": "Aug 18 13:18:45" }'


cleanup_tmp_files

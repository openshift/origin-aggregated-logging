# added 2015-07-22 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "user-defined type with '..' name"
add_rule 'version=2'
add_rule 'type=@IPaddr:%..:ipv4%'
add_rule 'type=@IPaddr:%..:ipv6%'
add_rule 'rule=:an ip address %ip:@IPaddr%'
execute 'an ip address 10.0.0.1'
assert_output_json_eq '{ "ip": "10.0.0.1" }'
execute 'an ip address 127::1'
assert_output_json_eq '{ "ip": "127::1" }'
execute 'an ip address 2001:DB8:0:1::10:1FF'
assert_output_json_eq '{ "ip": "2001:DB8:0:1::10:1FF" }'

cleanup_tmp_files

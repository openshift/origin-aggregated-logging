# added 2015-10-30 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "an actual test case for user-defined types"
add_rule 'version=2'
add_rule 'type=@endpid:%{"type":"alternative","parser":[ {"type": "literal", "text":"]"},{"type": "literal", "text":"]:"} ] }%'
add_rule 'type=@AUTOTYPE1:%iface:char-to:/%/%ip:ipv4%(%port:number%)'
add_rule 'type=@AUTOTYPE1:%iface:char-to:\x3a%\x3a%ip:ipv4%/%port:number%'
add_rule 'type=@AUTOTYPE1:%iface:char-to:\x3a%\x3a%ip:ipv4%'
add_rule 'rule=:a pid[%pid:number%%-:@endpid% b'
add_rule 'rule=:a iface %.:@AUTOTYPE1% b'

execute 'a pid[4711] b'
assert_output_json_eq '{ "pid": "4711" }'
# the next text needs priority assignment
#execute 'a pid[4712]: b'
#assert_output_json_eq '{ "pid": "4712" }'

execute 'a iface inside:10.0.0.1 b'
assert_output_json_eq '{ "ip": "10.0.0.1", "iface": "inside" }'

execute 'a iface inside:10.0.0.1/514 b'
assert_output_json_eq '{ "port": "514", "ip": "10.0.0.1", "iface": "inside" }'

execute 'a iface inside/10.0.0.1(514) b'
assert_output_json_eq '{ "port": "514", "ip": "10.0.0.1", "iface": "inside" }'

cleanup_tmp_files

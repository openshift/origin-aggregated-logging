# added 2015-06-18 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "Checkpoint LEA parser"
add_rule 'version=2'
add_rule 'rule=:%f:checkpoint-lea%'

execute 'tcp_flags: RST-ACK; src: 192.168.0.1;'
assert_output_json_eq '{ "f": { "tcp_flags": "RST-ACK", "src": "192.168.0.1" } }'


cleanup_tmp_files


# added 2016-10-17 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "a case that caused a segfault in practice"
add_rule 'version=2'
add_rule 'rule=:%host:ipv4% %{"type":"alternative","parser":[{"type":"literal","text":"-"},{"type":"number","name":"identd"}]}% %OK:word%'
execute '1.2.3.4 - TEST_OK'
assert_output_json_eq '{ "OK": "TEST_OK", "host": "1.2.3.4" }'
execute '1.2.3.4 100 TEST_OK'
assert_output_json_eq '{ "OK": "TEST_OK", "identd": "100", "host": "1.2.3.4" }'
execute '1.2.3.4 ERR TEST_OK'
assert_output_json_eq '{ "originalmsg": "1.2.3.4 ERR TEST_OK", "unparsed-data": "ERR TEST_OK" }'

cleanup_tmp_files

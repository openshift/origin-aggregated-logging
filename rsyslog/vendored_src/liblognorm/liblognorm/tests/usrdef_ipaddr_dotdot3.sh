# added 2015-07-22 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "user-defined type with '..' name embedded in other fields"
add_rule 'version=2'
add_rule 'type=@IPaddr:%..:ipv4%'
add_rule 'type=@IPaddr:%..:ipv6%'
add_rule 'type=@ipOrNumber:%..:@IPaddr{"priority":"1000"}%'
add_rule 'type=@ipOrNumber:%..:number%'
#add_rule 'type=@ipOrNumber:%..:@IPaddr%' # if we enable this instead of the above, the test would break
add_rule 'rule=:a word %w1:word% an ip address %ip:@ipOrNumber% another word %w2:word%'
execute 'a word word1 an ip address 10.0.0.1 another word word2'
assert_output_json_eq '{ "w2": "word2", "ip": "10.0.0.1", "w1": "word1" }'
execute 'a word word1 an ip address 2001:DB8:0:1::10:1FF another word word2'
assert_output_json_eq '{ "w2": "word2", "ip": "2001:DB8:0:1::10:1FF", "w1": "word1" }'
execute 'a word word1 an ip address 111 another word word2'
assert_output_json_eq '{ "w2": "word2", "ip": "111", "w1": "word1" }'

cleanup_tmp_files

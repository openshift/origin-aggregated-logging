# added 2015-11-05 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "named literal compaction"
add_rule 'version=2'
add_rule 'rule=:a word %w1:word% %l1:literal{"text":"l"}% b'
add_rule 'rule=:a word %w1:word% %l2:literal{"text":"l2"}% b'
add_rule 'rule=:a word %w1:word% l3 b'

execute 'a word w1 l b'
assert_output_json_eq '{ "l1": "l", "w1": "w1" }'

execute 'a word w1 l2 b'
assert_output_json_eq '{ "l2": "l2", "w1": "w1" }'

execute 'a word w1 l3 b'
assert_output_json_eq '{ "w1": "w1" }'

cleanup_tmp_files

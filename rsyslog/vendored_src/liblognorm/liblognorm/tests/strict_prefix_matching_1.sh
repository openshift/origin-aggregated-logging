# added 2015-11-05 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "one rule is strict prefix of a longer one"
add_rule 'version=2'
add_rule 'rule=:a word %w1:word%'
add_rule 'rule=:a word %w1:word% another word %w2:word%'

execute 'a word w1 another word w2'
assert_output_json_eq '{ "w2": "w2", "w1": "w1" }'

execute 'a word w1'
assert_output_json_eq '{ "w1": "w1" }'

cleanup_tmp_files

# added 2015-07-22 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "simple user-defined type"
add_rule 'version=2'
add_rule 'type=@hex-byte:%f1:hexnumber{"maxval": "255"}%'
add_rule 'rule=:a word %w1:word% a byte %   .:@hex-byte   % another word %w2:word%'
execute 'a word w1 a byte 0xff another word w2'
assert_output_json_eq '{ "w2": "w2", "f1": "0xff", "w1": "w1" }'

cleanup_tmp_files

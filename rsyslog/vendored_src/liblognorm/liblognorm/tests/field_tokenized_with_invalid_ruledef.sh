# added 2014-11-18 by singh.janmejay
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "tokenized field with invalid rule definition"

add_rule 'rule=:%arr:tokenized%'
execute '123 abc 456 def'
assert_output_contains '"unparsed-data": "123 abc 456 def"'
assert_output_contains '"originalmsg": "123 abc 456 def"'

reset_rules
add_rule 'rule=:%arr:tokenized: %'
execute '123 abc 456 def'
assert_output_contains '"unparsed-data": "123 abc 456 def"'
assert_output_contains '"originalmsg": "123 abc 456 def"'

reset_rules
add_rule 'rule=:%arr:tokenized:quux:%'
execute '123 abc 456 def'
assert_output_contains '"unparsed-data": "123 abc 456 def"'
assert_output_contains '"originalmsg": "123 abc 456 def"'

reset_rules
add_rule 'rule=:%arr:tokenized:quux:some_non_existant_type%'
execute '123 abc 456 def'
assert_output_contains '"unparsed-data": "123 abc 456 def"'
assert_output_contains '"originalmsg": "123 abc 456 def"'

reset_rules
add_rule 'rule=:%arr:tokenized:quux:some_non_existant_type:%'
execute '123 abc 456 def'
assert_output_contains '"unparsed-data": "123 abc 456 def"'
assert_output_contains '"originalmsg": "123 abc 456 def"'

reset_rules
add_rule 'rule=:%arr:tokenized::::%%%%'
execute '123 abc 456 def'
assert_output_contains '"unparsed-data": "123 abc 456 def"'
assert_output_contains '"originalmsg": "123 abc 456 def"'


cleanup_tmp_files


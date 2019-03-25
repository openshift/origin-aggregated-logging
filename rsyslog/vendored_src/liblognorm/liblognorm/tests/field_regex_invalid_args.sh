# added 2014-11-14 by singh.janmejay
# This file is part of the liblognorm project, released under ASL 2.0
export ln_opts='-oallowRegex'
. $srcdir/exec.sh

test_def $0 "invalid type for regex field with everything else defaulted"

add_rule 'rule=:%first:regex:[a-z]+:Q%'
execute 'foo'
assert_output_contains '"originalmsg": "foo"'
assert_output_contains '"unparsed-data": "foo"'

reset_rules
add_rule 'rule=:%first:regex:[a-z]+:%'
execute 'foo'
assert_output_contains '"originalmsg": "foo"'
assert_output_contains '"unparsed-data": "foo"'

reset_rules
add_rule 'rule=:%first:regex:[a-z]+:0:%'
execute 'foo'
assert_output_contains '"originalmsg": "foo"'
assert_output_contains '"unparsed-data": "foo"'

reset_rules
add_rule 'rule=:%first:regex:[a-z]+:0:0q%'
execute 'foo'
assert_output_contains '"originalmsg": "foo"'
assert_output_contains '"unparsed-data": "foo"'

reset_rules
add_rule 'rule=:%first:regex:[a-z]+:0a:0%'
execute 'foo'
assert_output_contains '"originalmsg": "foo"'
assert_output_contains '"unparsed-data": "foo"'

reset_rules
add_rule 'rule=:%first:regex:::::%%%'
execute 'foo'
assert_output_contains '"originalmsg": "foo"'
assert_output_contains '"unparsed-data": "foo"'


cleanup_tmp_files


# added 2015-05-05 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
# Note that this test produces an error message, as it encouters the
# runaway rule. This is OK and actually must happen. The prime point
# of the test is that it correctly loads the second rule, which
# would otherwise be consumed by the runaway rule.
. $srcdir/exec.sh

test_def $0 "runaway rule (unmatched percent signs)"

reset_rules
add_rule 'version=2'
add_rule 'rule=:test %f1:word unmatched percent'
add_rule 'rule=:%field:word%'

execute 'data'
assert_output_json_eq '{"field": "data"}'

cleanup_tmp_files

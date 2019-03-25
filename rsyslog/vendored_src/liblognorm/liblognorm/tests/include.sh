# added 2015-08-28 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "include (success case)"
reset_rules
add_rule 'version=2'
add_rule 'include=inc.rulebase'

reset_rules inc
add_rule 'version=2' inc
add_rule 'rule=:%field:mac48%' inc

execute 'f0:f6:1c:5f:cc:a2'
assert_output_json_eq '{"field": "f0:f6:1c:5f:cc:a2"}'

# single test is sufficient, because that only works if the include
# worked ;)

cleanup_tmp_files

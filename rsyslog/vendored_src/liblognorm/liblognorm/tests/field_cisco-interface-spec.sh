# added 2015-04-13 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "cisco-interface-spec syntax"
add_rule 'rule=:begin %field:cisco-interface-spec% end'

execute 'begin outside:176.97.252.102/50349 end'
assert_output_json_eq '{"field":  { "interface": "outside", "ip": "176.97.252.102", "port": "50349" } }'

execute 'begin outside:176.97.252.102/50349(DOMAIN\rainer) end'
# we need to add the backslash escape for the testbench plumbing
assert_output_json_eq '{"field": { "interface": "outside", "ip": "176.97.252.102", "port": "50349", "user": "DOMAIN\\rainer" } }'

execute 'begin outside:176.97.252.102/50349(test/rainer) end'
# we need to add the backslash escape for the testbench plumbing
assert_output_json_eq '{"field": { "interface": "outside", "ip": "176.97.252.102", "port": "50349", "user": "test/rainer" } }'

execute 'begin outside:176.97.252.102/50349(rainer) end'
# we need to add the backslash escape for the testbench plumbing
assert_output_json_eq '{"field": { "interface": "outside", "ip": "176.97.252.102", "port": "50349", "user": "rainer" } }'

execute 'begin outside:192.168.1.13/50179 (192.168.1.13/50179)(LOCAL\some.user) end'
assert_output_json_eq ' { "field": { "interface": "outside", "ip": "192.168.1.13", "port": "50179", "ip2": "192.168.1.13", "port2": "50179", "user": "LOCAL\\some.user" } }'

execute 'begin outside:192.168.1.13/50179 (192.168.1.13/50179) (LOCAL\some.user) end'
assert_output_json_eq ' { "field": { "interface": "outside", "ip": "192.168.1.13", "port": "50179", "ip2": "192.168.1.13", "port2": "50179", "user": "LOCAL\\some.user" } }'

execute 'begin 192.168.1.13/50179 (192.168.1.13/50179) (LOCAL\without.if) end'
assert_output_json_eq ' { "field": { "ip": "192.168.1.13", "port": "50179", "ip2": "192.168.1.13", "port2": "50179", "user": "LOCAL\\without.if" } }'

#
# Test for things that MUST NOT match!
#

# the SP before the second IP is missing:
execute 'begin outside:192.168.1.13/50179(192.168.1.13/50179)(LOCAL\some.user) end'
# note: the expected result looks a bit strange. This is the case because we
# cannot (yet?) detect that "(192.168.1.13/50179)" is not a valid user name.
assert_output_json_eq '{ "originalmsg": "begin outside:192.168.1.13\/50179(192.168.1.13\/50179)(LOCAL\\some.user) end", "unparsed-data": "(LOCAL\\some.user) end" }'


cleanup_tmp_files


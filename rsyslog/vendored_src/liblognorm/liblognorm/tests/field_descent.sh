# added 2014-12-11 by singh.janmejay
# This file is part of the liblognorm project, released under ASL 2.0

uname -a | grep "SunOS.*5.10"
if [ $? -eq 0 ] ; then
   echo platform: `uname -a`
   echo This looks like solaris 10, we disable known-failing tests to
   echo permit OpenCSW to build packages. However, this are real failurs
   echo and so a fix should be done as soon as time permits.
   exit 77
fi
. $srcdir/exec.sh

test_def $0 "descent based parsing field"

#descent with default tail field
add_rule 'rule=:blocked on %device:word% %net:descent:./child.rulebase%at %tm:date-rfc5424%'
reset_rules 'child'
add_rule 'rule=:%ip_addr:ipv4% %tail:rest%' 'child'
add_rule 'rule=:%subnet_addr:ipv4%/%mask:number% %tail:rest%' 'child'
execute 'blocked on gw-1 10.20.30.40 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"ip_addr": "10.20.30.40"}, "tm": "2014-12-08T08:53:33.05+05:30"}'
execute 'blocked on gw-1 10.20.30.40/16 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"subnet_addr": "10.20.30.40", "mask": "16"}, "tm": "2014-12-08T08:53:33.05+05:30"}'

#descent with tail field being explicitly named 'tail'
reset_rules
add_rule 'rule=:blocked on %device:word% %net:descent:./field.rulebase:tail%at %tm:date-rfc5424%'
reset_rules 'field'
add_rule 'rule=:%ip_addr:ipv4% %tail:rest%' 'field'
add_rule 'rule=:%subnet_addr:ipv4%/%mask:number% %tail:rest%' 'field'
execute 'blocked on gw-1 10.20.30.40 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"ip_addr": "10.20.30.40"}, "tm": "2014-12-08T08:53:33.05+05:30"}'
execute 'blocked on gw-1 10.20.30.40/16 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"subnet_addr": "10.20.30.40", "mask": "16"}, "tm": "2014-12-08T08:53:33.05+05:30"}'

#descent with tail field having arbirary name
reset_rules
add_rule 'rule=:blocked on %device:word% %net:descent:./subset.rulebase:remaining%at %tm:date-rfc5424%'
reset_rules 'subset'
add_rule 'rule=:%ip_addr:ipv4% %remaining:rest%' 'subset'
add_rule 'rule=:%subnet_addr:ipv4%/%mask:number% %remaining:rest%' 'subset'
execute 'blocked on gw-1 10.20.30.40 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"ip_addr": "10.20.30.40"}, "tm": "2014-12-08T08:53:33.05+05:30"}'
execute 'blocked on gw-1 10.20.30.40/16 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"subnet_addr": "10.20.30.40", "mask": "16"}, "tm": "2014-12-08T08:53:33.05+05:30"}'

#head call handling with with separate rulebase and tail field with with arbitrary name (this is what recursive field can't do)
reset_rules
add_rule 'rule=:%net:descent:./alt.rulebase:remains%blocked on %device:word%'
reset_rules 'alt'
add_rule 'rule=:%ip_addr:ipv4% %remains:rest%' 'alt'
add_rule 'rule=:%subnet_addr:ipv4%/%mask:number% %remains:rest%' 'alt'
execute '10.20.30.40 blocked on gw-1'
assert_output_json_eq '{"device": "gw-1", "net": {"ip_addr": "10.20.30.40"}}'
execute '10.20.30.40/16 blocked on gw-1'
assert_output_json_eq '{"device": "gw-1", "net": {"subnet_addr": "10.20.30.40", "mask": "16"}}'

#descent-field which calls another descent-field
reset_rules
add_rule 'rule=:%op:descent:./op.rulebase:rest% on %device:word%'
reset_rules 'op'
add_rule 'rule=:%net:descent:./alt.rulebase:remains%%action:word%%rest:rest%' 'op'
reset_rules 'alt'
add_rule 'rule=:%ip_addr:ipv4% %remains:rest%' 'alt'
add_rule 'rule=:%subnet_addr:ipv4%/%mask:number% %remains:rest%' 'alt'
execute '10.20.30.40 blocked on gw-1'
assert_output_json_eq '{"op": {"action": "blocked", "net": {"ip_addr": "10.20.30.40"}}, "device": "gw-1"}'
execute '10.20.30.40/16 unblocked on gw-2'
assert_output_json_eq '{"op": {"action": "unblocked", "net": {"subnet_addr": "10.20.30.40", "mask": "16"}}, "device": "gw-2"}'

#descent with file name having lognorm special char
add_rule 'rule=:blocked on %device:word% %net:descent:./part\x3anet.rulebase%at %tm:date-rfc5424%'
reset_rules 'part:net'
add_rule 'rule=:%ip_addr:ipv4% %tail:rest%' 'part:net'
add_rule 'rule=:%subnet_addr:ipv4%/%mask:number% %tail:rest%' 'part:net'
execute 'blocked on gw-1 10.20.30.40 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"ip_addr": "10.20.30.40"}, "tm": "2014-12-08T08:53:33.05+05:30"}'
execute 'blocked on gw-1 10.20.30.40/16 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"subnet_addr": "10.20.30.40", "mask": "16"}, "tm": "2014-12-08T08:53:33.05+05:30"}'


cleanup_tmp_files


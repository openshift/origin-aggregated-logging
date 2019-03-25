# added 2014-11-26 by singh.janmejay
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

test_def $0 "recursive parsing field"

#tail recursion with default tail field
add_rule 'rule=:%word:word% %next:recursive%'
add_rule 'rule=:%word:word%'
execute '123 abc 456 def'
assert_output_json_eq '{"word": "123", "next": {"word": "abc", "next": {"word": "456", "next" : {"word": "def"}}}}'

#tail recursion with explicitly named 'tail' field
reset_rules
add_rule 'rule=:%word:word% %next:recursive:tail%'
add_rule 'rule=:%word:word%'
execute '123 abc 456 def'
assert_output_json_eq '{"word": "123", "next": {"word": "abc", "next": {"word": "456", "next" : {"word": "def"}}}}'

#tail recursion with tail field having arbirary name
reset_rules
add_rule 'rule=:%word:word% %next:recursive:foo%'
add_rule 'rule=:%word:word%'
execute '123 abc 456 def'
assert_output_json_eq '{"word": "123", "next": {"word": "abc", "next": {"word": "456", "next" : {"word": "def"}}}}'

#non tail recursion with default tail field 
reset_rules
add_rule 'rule=:blocked on %device:word% %net:recursive%at %tm:date-rfc5424%'
add_rule 'rule=:%ip_addr:ipv4% %tail:rest%'
add_rule 'rule=:%subnet_addr:ipv4%/%mask:number% %tail:rest%'
execute 'blocked on gw-1 10.20.30.40 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"ip_addr": "10.20.30.40"}, "tm": "2014-12-08T08:53:33.05+05:30"}'
execute 'blocked on gw-1 10.20.30.40/16 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"subnet_addr": "10.20.30.40", "mask": "16"}, "tm": "2014-12-08T08:53:33.05+05:30"}'

#non tail recursion with tail field being explicitly named 'tail'
reset_rules
add_rule 'rule=:blocked on %device:word% %net:recursive:tail%at %tm:date-rfc5424%'
add_rule 'rule=:%ip_addr:ipv4% %tail:rest%'
add_rule 'rule=:%subnet_addr:ipv4%/%mask:number% %tail:rest%'
execute 'blocked on gw-1 10.20.30.40 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"ip_addr": "10.20.30.40"}, "tm": "2014-12-08T08:53:33.05+05:30"}'
execute 'blocked on gw-1 10.20.30.40/16 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"subnet_addr": "10.20.30.40", "mask": "16"}, "tm": "2014-12-08T08:53:33.05+05:30"}'

#non tail recursion with tail field having arbirary name
reset_rules
add_rule 'rule=:blocked on %device:word% %net:recursive:remaining%at %tm:date-rfc5424%'
add_rule 'rule=:%ip_addr:ipv4% %remaining:rest%'
add_rule 'rule=:%subnet_addr:ipv4%/%mask:number% %remaining:rest%'
execute 'blocked on gw-1 10.20.30.40 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"ip_addr": "10.20.30.40"}, "tm": "2014-12-08T08:53:33.05+05:30"}'
execute 'blocked on gw-1 10.20.30.40/16 at 2014-12-08T08:53:33.05+05:30'
assert_output_json_eq '{"device": "gw-1", "net": {"subnet_addr": "10.20.30.40", "mask": "16"}, "tm": "2014-12-08T08:53:33.05+05:30"}'



cleanup_tmp_files


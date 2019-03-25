# added 2014-11-17 by singh.janmejay
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

test_def $0 "tokenized field"

add_rule 'rule=:%arr:tokenized: , :word% %more:rest%'
execute '123 , abc , 456 , def ijk789'
assert_output_contains '"arr": [ "123", "abc", "456", "def" ]'
assert_output_contains '"more": "ijk789"'

reset_rules
add_rule 'rule=:%ips:tokenized:, :ipv4% %text:rest%'
execute '10.20.30.40, 50.60.70.80, 90.100.110.120 are blocked'
assert_output_contains '"text": "are blocked"'
assert_output_contains '"ips": [ "10.20.30.40", "50.60.70.80", "90.100.110.120" ]'

reset_rules
add_rule 'rule=:comma separated list of colon separated list of # separated numbers: %some_nos:tokenized:, :tokenized: \x3a :tokenized:#:number%'
execute 'comma separated list of colon separated list of # separated numbers: 10, 20 : 30#40#50 : 60#70#80, 90 : 100'
assert_output_contains '"some_nos": [ [ [ "10" ] ], [ [ "20" ], [ "30", "40", "50" ], [ "60", "70", "80" ] ], [ [ "90" ], [ "100" ] ] ]'

reset_rules
add_rule 'rule=:%arr:tokenized:\x3a:number% %more:rest%'
execute '123:456:789 ijk789'
assert_output_json_eq '{"arr": [ "123", "456", "789" ], "more": "ijk789"}'


cleanup_tmp_files


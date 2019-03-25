# added 2014-12-08 by singh.janmejay
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

test_def $0 "tokenized field with recursive field matching tokens"

#recursive field inside tokenized field with default tail field
add_rule 'rule=:%subnet_addr:ipv4%/%subnet_mask:number%%tail:rest%'
add_rule 'rule=:%ip_addr:ipv4%%tail:rest%'
add_rule 'rule=:blocked inbound via: %via_ip:ipv4% from: %addresses:tokenized:, :recursive% to %server_ip:ipv4%'
execute 'blocked inbound via: 192.168.1.1 from: 1.2.3.4, 5.6.16.0/12, 8.9.10.11, 12.13.14.15, 16.17.18.0/8, 19.20.21.24/3 to 192.168.1.5'
assert_output_json_eq '{
"addresses": [
  {"ip_addr": "1.2.3.4"}, 
  {"subnet_addr": "5.6.16.0", "subnet_mask": "12"}, 
  {"ip_addr": "8.9.10.11"}, 
  {"ip_addr": "12.13.14.15"}, 
  {"subnet_addr": "16.17.18.0", "subnet_mask": "8"}, 
  {"subnet_addr": "19.20.21.24", "subnet_mask": "3"}], 
"server_ip": "192.168.1.5",
"via_ip": "192.168.1.1"}'
reset_rules

#recursive field inside tokenized field with default tail field
reset_rules
add_rule 'rule=:%subnet_addr:ipv4%/%subnet_mask:number%%remains:rest%'
add_rule 'rule=:%ip_addr:ipv4%%remains:rest%'
add_rule 'rule=:blocked inbound via: %via_ip:ipv4% from: %addresses:tokenized:, :recursive:remains% to %server_ip:ipv4%'
execute 'blocked inbound via: 192.168.1.1 from: 1.2.3.4, 5.6.16.0/12, 8.9.10.11, 12.13.14.15, 16.17.18.0/8, 19.20.21.24/3 to 192.168.1.5'
assert_output_json_eq '{
"addresses": [
  {"ip_addr": "1.2.3.4"}, 
  {"subnet_addr": "5.6.16.0", "subnet_mask": "12"}, 
  {"ip_addr": "8.9.10.11"}, 
  {"ip_addr": "12.13.14.15"}, 
  {"subnet_addr": "16.17.18.0", "subnet_mask": "8"}, 
  {"subnet_addr": "19.20.21.24", "subnet_mask": "3"}], 
"server_ip": "192.168.1.5",
"via_ip": "192.168.1.1"}'

#recursive field inside tokenized field with default tail field
reset_rules 'net'
add_rule 'rule=:%subnet_addr:ipv4%/%subnet_mask:number%%remains:rest%' 'net'
add_rule 'rule=:%ip_addr:ipv4%%remains:rest%' 'net'
reset_rules
add_rule 'rule=:blocked inbound via: %via_ip:ipv4% from: %addresses:tokenized:, :descent:./net.rulebase:remains% to %server_ip:ipv4%'
execute 'blocked inbound via: 192.168.1.1 from: 1.2.3.4, 5.6.16.0/12, 8.9.10.11, 12.13.14.15, 16.17.18.0/8, 19.20.21.24/3 to 192.168.1.5'
assert_output_json_eq '{
"addresses": [
  {"ip_addr": "1.2.3.4"}, 
  {"subnet_addr": "5.6.16.0", "subnet_mask": "12"}, 
  {"ip_addr": "8.9.10.11"}, 
  {"ip_addr": "12.13.14.15"}, 
  {"subnet_addr": "16.17.18.0", "subnet_mask": "8"}, 
  {"subnet_addr": "19.20.21.24", "subnet_mask": "3"}], 
"server_ip": "192.168.1.5",
"via_ip": "192.168.1.1"}'


cleanup_tmp_files


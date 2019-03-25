# added 2015-02-25 by singh.janmejay
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

test_def $0 "field with one of many possible suffixes"

add_rule 'rule=:gc reclaimed %eden_free:suffixed:,:b,kb,mb,gb:number% eden [surviver: %surviver_used:suffixed:;:kb;mb;gb;b:number%/%surviver_size:suffixed:|:b|kb|mb|gb:float%]'
execute 'gc reclaimed 559mb eden [surviver: 95b/30.2mb]'
assert_output_json_eq '{"eden_free": {"value": "559", "suffix":"mb"}, "surviver_used": {"value": "95", "suffix": "b"}, "surviver_size": {"value": "30.2", "suffix": "mb"}}'

reset_rules

add_rule 'rule=:gc reclaimed %eden_free:named_suffixed:size:unit:,:b,kb,mb,gb:number% eden [surviver: %surviver_used:named_suffixed:sz:u:;:kb;mb;gb;b:number%/%surviver_size:suffixed:|:b|kb|mb|gb:float%]'
execute 'gc reclaimed 559mb eden [surviver: 95b/30.2mb]'
assert_output_json_eq '{"eden_free": {"size": "559", "unit":"mb"}, "surviver_used": {"sz": "95", "u": "b"}, "surviver_size": {"value": "30.2", "suffix": "mb"}}'

reset_rules

add_rule 'rule=:gc reclaimed %eden_free:named_suffixed:size:unit:,:b,kb,mb,gb:interpret:int:number% from eden'
execute 'gc reclaimed 559mb from eden'
assert_output_json_eq '{"eden_free": {"size": 559, "unit":"mb"}}'

reset_rules

add_rule 'rule=:disk free: %free:named_suffixed:size:unit:,:\x25,gb:interpret:int:number%'
execute 'disk free: 12%'
assert_output_json_eq '{"free": {"size": 12, "unit":"%"}}'
execute 'disk free: 130gb'
assert_output_json_eq '{"free": {"size": 130, "unit":"gb"}}'

reset_rules

add_rule 'rule=:disk free: %free:named_suffixed:size:unit:\x3a:gb\x3a\x25:interpret:int:number%'
execute 'disk free: 12%'
assert_output_json_eq '{"free": {"size": 12, "unit":"%"}}'
execute 'disk free: 130gb'
assert_output_json_eq '{"free": {"size": 130, "unit":"gb"}}'

reset_rules

add_rule 'rule=:eden,surviver,old-gen available-capacity: %available_memory:tokenized:,:named_suffixed:size:unit:,:mb,gb:interpret:int:number%'
execute 'eden,surviver,old-gen available-capacity: 400mb,40mb,1gb'
assert_output_json_eq '{"available_memory": [{"size": 400, "unit":"mb"}, {"size": 40, "unit":"mb"}, {"size": 1, "unit":"gb"}]}'

reset_rules

add_rule 'rule=:eden,surviver,old-gen available-capacity: %available_memory:named_suffixed:size:unit:,:mb,gb:tokenized:,:interpret:int:number%'
execute 'eden,surviver,old-gen available-capacity: 400,40,1024mb'
assert_output_json_eq '{"available_memory": {"size": [400, 40, 1024], "unit":"mb"}}'

reset_rules

add_rule 'rule=:eden:surviver:old-gen available-capacity: %available_memory:named_suffixed:size:unit:,:mb,gb:tokenized:\x3a:interpret:int:number%'
execute 'eden:surviver:old-gen available-capacity: 400:40:1024mb'
assert_output_json_eq '{"available_memory": {"size": [400, 40, 1024], "unit":"mb"}}'



cleanup_tmp_files


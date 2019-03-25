# added 2015-02-26 by singh.janmejay
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "field with one of many possible suffixes, but invalid ruledef"

add_rule 'rule=:reclaimed %eden_free:suffixe:,:b,kb,mb,gb:number% eden'
execute 'reclaimed 559mb eden'
assert_output_json_eq '{ "originalmsg": "reclaimed 559mb eden", "unparsed-data": "559mb eden" }'

reset_rules

add_rule 'rule=:reclaimed %eden_free:suffixed% eden'
execute 'reclaimed 559mb eden'
assert_output_json_eq '{ "originalmsg": "reclaimed 559mb eden", "unparsed-data": "559mb eden" }'

reset_rules

add_rule 'rule=:reclaimed %eden_free:suffixed:% eden'
execute 'reclaimed 559mb eden'
assert_output_json_eq '{ "originalmsg": "reclaimed 559mb eden", "unparsed-data": "559mb eden" }'

reset_rules

add_rule 'rule=:reclaimed %eden_free:suffixed:kb,mb% eden'
execute 'reclaimed 559mb eden'
assert_output_json_eq '{ "originalmsg": "reclaimed 559mb eden", "unparsed-data": "559mb eden" }'

reset_rules

add_rule 'rule=:reclaimed %eden_free:suffixed:kb,mb% eden'
execute 'reclaimed 559mb eden'
assert_output_json_eq '{ "originalmsg": "reclaimed 559mb eden", "unparsed-data": "559mb eden" }'

reset_rules

add_rule 'rule=:reclaimed %eden_free:suffixed:,:% eden'
execute 'reclaimed 559mb eden'
assert_output_json_eq '{ "originalmsg": "reclaimed 559mb eden", "unparsed-data": "559mb eden" }'

reset_rules

add_rule 'rule=:reclaimed %eden_free:suffixed:,:kb,mb% eden'
execute 'reclaimed 559mb eden'
assert_output_json_eq '{ "originalmsg": "reclaimed 559mb eden", "unparsed-data": "559mb eden" }'

reset_rules

add_rule 'rule=:reclaimed %eden_free:suffixed:,:kb,mb:% eden'
execute 'reclaimed 559mb eden'
assert_output_json_eq '{ "originalmsg": "reclaimed 559mb eden", "unparsed-data": "559mb eden" }'

reset_rules

add_rule 'rule=:reclaimed %eden_free:suffixed:,:kb,mb:floa% eden'
execute 'reclaimed 559mb eden'
assert_output_json_eq '{ "originalmsg": "reclaimed 559mb eden", "unparsed-data": "559mb eden" }'

reset_rules

add_rule 'rule=:reclaimed %eden_free:suffixed:,:kb,m:b:floa% eden'
execute 'reclaimed 559mb eden'
assert_output_json_eq '{ "originalmsg": "reclaimed 559mb eden", "unparsed-data": "559mb eden" }'


cleanup_tmp_files


# added 2016-11-08 by Rainer Gerhards
. $srcdir/exec.sh

test_def $0 "annotate functionality"

reset_rules
add_rule 'version=2'
add_rule 'rule=ABC,WIN:<%-:number%>1 %-:date-rfc5424% %-:word% %tag:word% - - -'
add_rule 'rule=ABC:<%-:number%>1 %-:date-rfc5424% %-:word% %tag:word% + - -'
add_rule 'rule=WIN:<%-:number%>1 %-:date-rfc5424% %-:word% %tag:word% . - -'
add_rule 'annotate=WIN:+annot1="WIN" # inline-comment'
add_rule 'annotate=ABC:+annot2="ABC"'

execute '<37>1 2016-11-03T23:59:59+03:00 server.example.net TAG . - -'
assert_output_json_eq '{ "tag": "TAG", "annot1": "WIN" }'

execute '<37>1 2016-11-03T23:59:59+03:00 server.example.net TAG + - -'
assert_output_json_eq '{ "tag": "TAG", "annot2": "ABC" }'

execute '<6>1 2016-09-02T07:41:07+02:00 server.example.net TAG - - -'
assert_output_json_eq '{ "tag": "TAG", "annot1": "WIN", "annot2": "ABC" }'

cleanup_tmp_files

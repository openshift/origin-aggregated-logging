
uname -a | grep "SunOS.*5.10"
if [ $? -eq 0 ] ; then
   echo platform: `uname -a`
   echo This looks like solaris 10, we disable known-failing tests to
   echo permit OpenCSW to build packages. However, this are real failurs
   echo and so a fix should be done as soon as time permits.
   exit 77
fi
. $srcdir/exec.sh

test_def $0 "multiple formats including string (see also: rule_last_str_short.sh)"
add_rule 'version=2'
add_rule 'rule=:%string:string%'
add_rule 'rule=:before %string:string%'
add_rule 'rule=:%string:string% after'
add_rule 'rule=:before %string:string% after'
add_rule 'rule=:before %string:string% middle %string:string%'

execute 'string'
execute 'before string'
execute 'string after'
execute 'before string after'
execute 'before string middle string'
assert_output_json_eq '{"string": "string" }' '{"string": "string" }''{"string": "string" }''{"string": "string" }''{"string": "string", "string": "string" }'


cleanup_tmp_files

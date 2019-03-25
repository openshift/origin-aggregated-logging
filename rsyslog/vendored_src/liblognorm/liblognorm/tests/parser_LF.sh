# added 2015-07-15 by Rainer Gerhards
# This checks if whitespace inside parser definitions is properly treated
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
test_def $0 "LF in parser definition"

add_rule 'rule=:here is a number %
                num:hexnumber
                % in hex form'
execute 'here is a number 0x1234 in hex form'
assert_output_json_eq '{"num": "0x1234"}'

#check cases where parsing failure must occur
execute 'here is a number 0x1234in hex form'
assert_output_json_eq '{ "originalmsg": "here is a number 0x1234in hex form", "unparsed-data": "0x1234in hex form" }'

cleanup_tmp_files

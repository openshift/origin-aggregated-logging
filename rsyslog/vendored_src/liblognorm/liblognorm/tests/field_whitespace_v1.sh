# added 2015-03-12 by Rainer Gerhards
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

test_def $0 "whitespace parser"
# the "word" parser unfortunatly treats everything except
# a SP as being in the word. So a HT inside a word is
# permitted, which does not work well with what we
# want to test here. to solve this problem, we use op-quoted-string.
# However, we must actually quote the samples with HT, because
# that parser also treats HT as being part of the word. But thanks
# to the quotes, we can force it to not do that.
# rgerhards, 2015-04-30
add_rule 'rule=:%a:op-quoted-string%%-:whitespace%%b:op-quoted-string%'

execute 'word1  word2' # multiple spaces
assert_output_json_eq '{ "b": "word2", "a": "word1" }'
execute 'word1 word2' # single space
assert_output_json_eq '{ "b": "word2", "a": "word1" }'
execute '"word1"	"word2"' # tab (US-ASCII HT)
assert_output_json_eq '{ "b": "word2", "a": "word1" }'
execute '"word1"	   	"word2"' # mix of tab and spaces
assert_output_json_eq '{ "b": "word2", "a": "word1" }'


cleanup_tmp_files


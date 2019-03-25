# added 2015-09-21 by singh.janmejay
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

msg="foo"
for i in $(seq 1 10); do
		msg="${msg},${msg},abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ${i}"
done

test_def $0 "float field"
add_rule 'rule=:%line:rest%'
execute $msg
assert_output_json_eq "{\"line\": \"$msg\"}"

cleanup_tmp_files


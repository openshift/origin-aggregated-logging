# added 2015-11-05 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0

. $srcdir/exec.sh

test_def $0 "one rule is strict prefix of a longer one"
add_rule 'version=2'
add_rule 'prefix=%timestamp:date-rfc3164% %hostname:word% BL-WLC01: *%programname:char-to:\x3a%: %timestamp:date-rfc3164%.%fracsec:number%:'
add_rule 'rule=wifi: #LOG-3-Q_IND: webauth_redirect.c:1238 read error on server socket, errno=131[...It occurred %count:number% times.!]'
add_rule 'rule=wifi: #LOG-3-Q_IND: webauth_redirect.c:1238 read error on server socket, errno=131'

execute 'Sep 28 23:53:19 192.168.123.99 BL-WLC01: *dtlArpTask: Sep 28 23:53:19.614: #LOG-3-Q_IND: webauth_redirect.c:1238 read error on server socket, errno=131'
assert_output_json_eq '{ "fracsec": "614", "timestamp": "Sep 28 23:53:19", "programname": "dtlArpTask", "hostname": "192.168.123.99" }'

cleanup_tmp_files

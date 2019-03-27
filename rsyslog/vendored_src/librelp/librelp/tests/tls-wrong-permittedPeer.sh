#!/bin/bash
. ${srcdir}/test-framework.sh
startup_receiver -T -a "name" -x ${srcdir}/tls-certs/ca.pem -y ${srcdir}/tls-certs/cert.pem -z ${srcdir}/tls-certs/key.pem -P "wrong name"

echo 'Send Message...'
./send -t 127.0.0.1 -p $TESTPORT -m "testmessage" -T -a "name" -x ${srcdir}/tls-certs/ca.pem -y ${srcdir}/tls-certs/cert.pem -z ${srcdir}/tls-certs/key.pem -P "wrong name" -v 2>&1 | tee librelp.out.log

stop_receiver
check_output "librelp: auth error: authdata:'DNSname: rsyslog; ', ecode 10034, emsg 'no permited name found'"
terminate

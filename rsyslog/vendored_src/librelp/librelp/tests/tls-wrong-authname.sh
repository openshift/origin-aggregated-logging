#!/bin/bash
. ${srcdir}/test-framework.sh

./receive -p $TESTPORT -T -a "anon" -x tls-certs/ca.pem -y tls-certs/cert.pem -z tls-certs/key.pem -P "rsyslog" &> librelp.out.log
check_output "relpSrvSetAuthMode(pRelpSrv, authMode)"

./send -t 127.0.0.1 -p $TESTPORT -m "testmessage" -T -a "anon" -x tls-certs/ca.pem -y tls-certs/cert.pem -z tls-certs/key.pem -P "rsyslog" -v &> librelp.out.log
check_output "relpCltSetAuthMode(pRelpClt, authMode)"

terminate

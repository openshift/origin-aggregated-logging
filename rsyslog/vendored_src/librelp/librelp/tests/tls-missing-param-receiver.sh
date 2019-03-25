#!/bin/bash
# This is a self test for the testbench! It does NOT test Relp.
echo 'Start Receiver...'
. ${srcdir}/test-framework.sh

./receive -p $TESTPORT -T -a "name" -y ${srcdir}/tls-certs/cert.pem -z ${srcdir}/tls-certs/key.pem -P "rsyslog" > librelp.out.log

check_output "receive: parameter missing; certificates and permittedPeer required"
terminate

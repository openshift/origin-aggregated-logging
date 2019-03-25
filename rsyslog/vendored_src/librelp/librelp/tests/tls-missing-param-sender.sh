#!/bin/bash
# This is a self test for the testbench! It does NOT test Relp.
. ${srcdir}/test-framework.sh

echo 'Send Message...'
./send -t 127.0.0.1 -p $TESTPORT -m "testmessage" -T -a "name" -y ${srcdir}/tls-certs/cert.pem -z ${srcdir}/tls-certs/key.pem -P "rsyslog" > librelp.out.log

check_output "send: parameter missing; certificates and permittedPeer required"
terminate

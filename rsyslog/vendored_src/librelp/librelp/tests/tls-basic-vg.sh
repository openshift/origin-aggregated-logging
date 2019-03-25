#!/bin/bash
if [ `uname` = "SunOS" ] ; then
   echo "This test currently does not work on all flavors of Solaris."
   exit 77
fi
if [ `uname` = "FreeBSD" ] ; then
   echo "This test currently does not work on FreeBSD."
   exit 77
fi

. ${srcdir}/test-framework.sh

TESTPORT=20514
echo 'Start Receiver...'
valgrind ./receive -p $TESTPORT -T -a "name" -x ${srcdir}/tls-certs/ca.pem -y ${srcdir}/tls-certs/cert.pem -z ${srcdir}/tls-certs/key.pem -P "rsyslog" > librelp.out.log &
PID=$!

sleep 1

echo 'Send Message...'
valgrind ./send -t 127.0.0.1 -p $TESTPORT -m "testmessage" -T -a "name" -x ${srcdir}/tls-certs/ca.pem -y ${srcdir}/tls-certs/cert.pem -z ${srcdir}/tls-certs/key.pem -P "rsyslog"

echo 'Stop Receiver...'
kill $PID

check_output "testmessage"
terminate


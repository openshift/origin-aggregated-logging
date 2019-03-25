#!/bin/bash
. ${srcdir}/test-framework.sh
startup_receiver -T

echo 'Send Message...'
./send -t 127.0.0.1 -p $TESTPORT -m "testmessage" -T

stop_receiver
check_output "testmessage"
terminate

#!/bin/bash
. ${srcdir}/test-framework.sh
startup_receiver

echo 'Send Message...'
./send -t 127.0.0.1 -p $TESTPORT -m "testmessage" -d 131072

stop_receiver
check_output "testmessage"
terminate

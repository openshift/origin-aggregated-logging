#!/bin/bash
# This file contains the test framework, that is common code
# used by all tests.
# Copyright (C) 2018 by Rainer Gerhards

# "config settings" for the testbench
TB_TIMEOUT_STARTUP=400  # 40 seconds - Solaris sometimes needs this...
TESTPORT=30514
#OPT_VERBOSE=-v # uncomment to get verbose output

######################################################################
# functions
######################################################################

# $1 is name of pidfile to wait for
function wait_process_startup_via_pidfile() {
	let "i=0"
	while test ! -f $1 ; do
		printf "startup wait %s\n" $i
		sleep .100
		let "i++"
		if test $i -gt $TB_TIMEOUT_STARTUP
		then
		   printf "ABORT! Timeout waiting on startup\n"
		   exit 1
		fi
	done
	printf "program started up, pidfile $1 contains $(cat $1)\n"
}


# start receiver, add receiver command line parameters after function name
function startup_receiver() {
	printf 'Starting Receiver...\n'
	./receive -p $TESTPORT -F receive.pid $OPT_VERBOSE $* > librelp.out.log &
	export RECEIVE_PID=$!
	printf "got receive pid $RECEIVE_PID\n"
	wait_process_startup_via_pidfile receive.pid
	sleep 1
	printf 'Receiver running\n'
}

# stop receiver
function stop_receiver() {
	kill $(cat receive.pid)
	wait $(cat receive.pid) &> /dev/null
	#kill $RECEIVE_PID
	printf "receiver stopped\n"
}

# $1 is the value to check for
# $2 (optinal) is the file to check
function check_output() {
	EXPECTED="$1"
	if [ "$2" == "" ] ; then
		FILE_TO_CHECK="librelp.out.log"
	else
		FILE_TO_CHECK="$2"
	fi
	grep "$EXPECTED" $FILE_TO_CHECK > /dev/null
	if [ $? -ne 0 ]; then
		printf "\nFAIL: expected message not found. Expected:\n"
		printf "%s\n" "$EXPECTED"
		printf "\n$FILE_TO_CHECK actually is:\n"
		cat $FILE_TO_CHECK
		exit 1
	fi
}

# cleanup temporary
# note: on solaris,
# get full command line: /usr/ucb/ps awwx
# find who listens on port:
# netstat -an | grep $TESTPORT
# ./CI/solaris-findport.sh $TESTPORT
function cleanup() {
	if [ "$(uname)" == "SunOS" ] ; then
		pkill -x receive
		echo pkill result $?
	fi
	rm -f receive.pid librelp.out.log *.err.log
}

# cleanup at end of regular test run
function terminate() {
	cleanup
	printf "$0 SUCCESS\n"
}

######################################################################
# testbench initialization code - do this LAST here in the file
######################################################################
printf "============================================================\n"
printf "Test: $0\n"
printf "============================================================\n"

# on Solaris we still have some issues sometimes. Please keep this
# informational info inside the framework until this can be totally
# considered revolved - rgerhards, 2018-04-17
if [ "$(uname)" == "SunOS" ] ; then
	/usr/ucb/ps awwx
	echo pgrep
	pgrep receive
	echo next
	ps -efl
	netstat -an | grep $TESTPORT
	CI/solaris-findport.sh $TESTPORT
fi

cleanup # we do cleanup in case it was not done previously

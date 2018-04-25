# How to Troubleshoot CI problems

When a PR has a CI test failure, the first thing to look at is the test
output.  The PR will have a comment like `The following tests failed, say
/retest to rerun them all:`.  Beneath that will be a table listing the jobs
that failed.  Click on the `link` in the `Details` column.  This document is
primarily concerned with problems in `STARTING STAGE: RUN LOGGING TESTS`.

## Job Output
First, look for errors.  They will usually look like this:
```
########## STARTING STAGE: RUN LOGGING TESTS ##########
... skipping 666 lines ...
[ERROR] PID 6714: hack/lib/cmd.sh:617: `return "${return_code}"` exited with status 1.
... skipping 5 lines ...
[ERROR] curator test finished at Tue Apr 24 21:37:08 UTC 2018
... skipping 4 lines ...
[WARNING] Logging test suite test-curator failed at Tue Apr 24 21:39:24 UTC 2018
```

By default the output is elided - there will be sections like this:
```
... skipping 362 lines ...
```
If you mouse left click on these, they will expand showing you the full
output.  Lines that begin with `[ERROR]` and `[WARNING]` are not elided.

Let's find the offending line, where the test failed.  Click on the ominous
`... skipping 666 lines ...` to expand it like this:
```
FAILURE after 119.609s: test/curator.sh:329: executing 'oc logs logging-curator-ops-3-txszj 2>&1 | grep -c 'curator run finish'' expecting any result and text '1'; re-trying every 0.2s until completion or 120.000s: the command timed out
Standard output from the command:
0
... repeated 269 times
Standard error from the command:
```
This means that curator ops was supposed to log the message `curator run
finish` to its log `1` time, but did not - `grep -c` returns `0` when no match
is found, which is why the standard output of the command was `0` 269 times.
Here is what test/curator.sh line 329 looks like:

    os::cmd::try_until_text "oc logs $curpod 2>&1 | grep -c 'curator run finish'" 1 $(( 2 * minute ))

`os::cmd::try_until_text` will repeat the given command a couple of times per
second for the given duration `$(( 2 * minute ))` or 2 minutes, will collect
the output, and will try to combine and count duplicated lines.

If you need more specific information about where in the file/stack the error
occurred, click on the `... skipping 5 lines ...` link and it will usually give
you a stacktrace like this:

    [INFO] 		Stack Trace: 
    [INFO] 		  1: hack/lib/cmd.sh:617: `return "${return_code}"`
    [INFO] 		  2: test/curator.sh:329: os::cmd::try_until_text
    [INFO] 		  3: test/curator.sh:446: basictest
    [INFO]   Exiting with code 1.

## Artifacts - logs/containers

If the log did not contain the output we were looking for, what exactly did the
log contain?  Did we capture the pod log?  At the top of the result page is a
link called `artifacts`.  These are logs and files collected from the test
run.  Click on the `artifacts` folder, then the `scripts` folder, then the
`entrypoint` folder.  There are two folders here - `logs/containers` contains the pod and
container logs from the _end_ of the test, so if the pod was restarted, we
might not have the right info.  We are looking for the curator ops pod log.
There are many log files here in the following format:

    k8s_POD_something.....

You will usually ignore those.  We're looking for the actual pod log, which
will look like this:

    k8s_curator_logging-curator-ops-N-xxxxx_.....log

Click on the file to open it:

    Traceback (most recent call last):
      File "run_cron.py", line 91, in <module>
        ccj = CuratorCronJob()
      File "run_cron.py", line 15, in __init__
        curator_cmd =   CuratorCmd()
      File "curator_cmd.py", line 32, in __init__
        parser = Parser(config_file)
      File "parser.py", line 29, in __init__
        self.default_count = int(os.getenv('CURATOR_DEFAULT_DAYS', 31))
    ValueError: invalid literal for int() with base 10: ''

That would explain why the test failed - we hit some unexpected error.

## Artifacts - artifacts

The `entrypoint` folder has a folder called `artifacts` - this is for test
specific logs, files, etc.  The test framework has two shell functions -
`artifact_log` and `artifact_out`.  These are used in tests like this:

    oc adm new-project $proj --node-selector='' 2>&1 | artifact_out

`artifact_log` is used to write specific values e.g. `artifact_log foo bar`.
These commands create a file in the `artifacts` folder called
`NAME-OF-TEST-artifacts.txt` e.g. `access_control.sh-artifacts.txt`.  The
new-project output looks like this:

    [2018-04-24T22:17:08.560+0000] Created project access-control-1

The test may also create files in the `artifacts` folder.  These are usually
named after the test e.g. `debug_level_logs-ops.json`.  Their usage is test
specific - you'll have to look at the code for the test to determine what the
file contains.  A test can write to `$ARTIFACT_DIR/testname-somefile.txt` and
have that file be placed in the `artifacts` folder.

A test may also write test specific pod logs to the `$ARTIFACT_DIR`, especially
if the test restarts pods and wants to capture the log output.  It is quite
common to see code like this in the test `cleanup` function:

    oc logs $fluentd_pod > $ARTIFACT_DIR/mux-client-mode-fluentd-pod.log 2>&1
    restart fluentd

If you are debugging a test, it is probably a good idea to add `artifact_out`
in several places, as well as dumping logs and temp files to `$ARTIFACT_DIR`.

## wait_for_fluentd_to_catch_up

In many cases you will see a test failure in `wait_for_fluentd_to_catch_up`.
This is because this function is used many times in many tests.  It will write
an apps log (by querying Kibana with a non-existent unique url, to make it
generate a 404 to its log), and an ops log (using the `logger` command with a
unique SYSLOG_IDENTIFIER and log message), then poll Elasticsearch with
searches until the log record is found.  There are many reasons why this would
fail - a bug in the code under test, misconfiguration of fluentd or
Elasticsearch, etc.  The function tries to identify the source of the log
record when there is a failure.  For instance, for app logs, it tries to look
for the message in `/var/log/containers/*.log` (for json-file) or in the
journal (for journald).  If it doesn't find the message, this may indicate that
there was a problem in Kibana or the container run time, that the log wasn't
delivered, in which case, you may have to look at the journal (journalctl) for
some of the container runtime components (e.g. `journalctl -u docker`).  The
function will also use `journalctl` to look for the ops logs (and apps logs if
using log-driver=journald).  If the record is found in the source, this means
that fluentd was unable to send the log to Elasticsearch.  The next place to
look then is the fluentd logs (and mux logs if the test uses mux).  You might
see error messages or exceptions in the fluentd logs.  If the test does not
preserve the fluentd log from the test run, you might need to add a fluentd log
dump to an `$ARTIFACT_LOG/test-fluentd-pod.log` file.

For persistent errors, you might need to widen the search e.g. look at the
output and logs from the previous test - maybe it didn't clean up after itself,
which is why your test gets a strange `fluentd not running` error before it
even hits your main test code.

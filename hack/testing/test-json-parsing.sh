#! /bin/bash

# test that logging will parse the message field containing
# embedded JSON into its component fields, and use the
# original message field in the embedded JSON

if [ -n "${VERBOSE:-}" ]; then
  set -ex
else
  set -e
  VERBOSE=
fi
set -o nounset
set -o pipefail

if ! type get_running_pod > /dev/null 2>&1 ; then
    . ${OS_O_A_L_DIR:-../..}/deployer/scripts/util.sh
fi

ARTIFACT_DIR=${ARTIFACT_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging}
if [ ! -d $ARTIFACT_DIR ] ; then
    mkdir -p $ARTIFACT_DIR
fi

# generate a log message in the Kibana logs - Kibana log messages are in JSON format:
# {"type":"response","@timestamp":"2017-04-07T02:03:37Z","tags":[],"pid":1,"method":"get","statusCode":404,"req":{"url":"/ca30cead-d470-4db8-a2a2-bb71439987e2","method":"get","headers":{"user-agent":"curl/7.29.0","host":"localhost:5601","accept":"*/*"},"remoteAddress":"127.0.0.1","userAgent":"127.0.0.1"},"res":{"statusCode":404,"responseTime":3,"contentLength":9},"message":"GET /ca30cead-d470-4db8-a2a2-bb71439987e2 404 3ms - 9.0B"}
# logging should parse this and make "type", "tags", "statusCode", etc. as top level fields
# the "message" field should contain only the embedded message and not the entire JSON blob

es_pod=`get_running_pod es`
uuid_es=`uuidgen`
echo Adding test message $uuid_es to Kibana . . .
add_test_message $uuid_es
rc=0
timeout=600
echo Waiting $timeout seconds for $uuid_es to show up in Elasticsearch . . .
if espod=$es_pod myproject=project.logging. mymessage=$uuid_es expected=1 \
    wait_until_cmd_or_err test_count_expected test_count_err $timeout ; then
    echo good - $0: found 1 record project logging for $uuid_es
else
    echo failed - $0: not found 1 record project logging for $uuid_es after $timeout seconds
    echo "Checking journal for $uuid_es..."
    if journalctl | grep $uuid_es ; then
        echo "Found $uuid_es in journal"
    else
        echo "Unable to find $uuid_es in journal"
    fi

    exit 1
fi

echo Testing if record is in correct format . . .
query_es_from_es $es_pod project.logging. _search message $uuid_es | \
    python test-json-parsing.py $uuid_es

echo Success: $0 passed
exit 0

#!/bin/bash

# test bulk rejection handling
source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
trap os::test::junit::reconcile_output EXIT
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/bulk_rejection"

LOGGING_NS=${LOGGING_NS:-openshift-logging}
espod=$( get_es_pod es )
esopspod=$( get_es_pod es-ops )
esopspod=${esopspod:-$espod}

function cleanup() {
    local result_code="$?"
    set +e
    if [ -n "${bulkdonefile:-}" ] ; then
        echo done > $bulkdonefile
    fi
    if [ -n "${bulktestjson:-}" -a -f "${bulktestjson:-}" ] ; then
        rm -f $bulktestjson
    fi
    if [ -f "${es_settings:-}" ] ; then
        echo restore settings | artifact_out
        cat $es_settings | artifact_out
        cat $es_settings | curl_es_input $espod /_cluster/settings -XPUT --data-binary @- | jq . | artifact_out
        rm -f $es_settings
    fi
    curl_es $espod /bulkindextest -XDELETE | jq . | artifact_out
    fpod=$( get_running_pod fluentd )
    if [ -f /var/log/fluentd.log ] ; then
        cp /var/log/fluentd.log $ARTIFACT_DIR/fluentd-with-bulk-index-rejections.log
    else
        oc logs $fpod > $ARTIFACT_DIR/fluentd-with-bulk-index-rejections.log
    fi
    if [ -n "${f_cm:-}" -a -f "${f_cm:-}" ] ; then
        oc replace --force -f $f_cm
    fi
    if [ -n "${f_ds:-}" -a -f "${f_ds:-}" ] ; then
        oc replace --force -f $f_ds
    fi
    os::cmd::try_until_failure "oc describe pod $fpod"
    sleep 1
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    if [ -n "${bulkdonefile:-}" -a -f "${bulkdonefile:-}" ] ; then
        rm -f $bulkdonefile
    fi
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $result_code
}

trap cleanup EXIT

# save current fluentd settings
f_cm=$( mktemp )
f_ds=$( mktemp )

oc get cm/logging-fluentd -o yaml > $f_cm
oc get ds/logging-fluentd -o yaml > $f_ds

# turn on debug output
cat $f_cm | \
    sed -e 's,@include configs.d/openshift/system.conf,<system>\
      log_level debug\
    </system>,' | oc replace --force -f -

oc set env ds/logging-fluentd DEBUG=true

# save current es settings

es_settings=$( mktemp )
curl_es $espod /_cluster/settings | jq . > $es_settings

# change bulk queue_size and size to 1 to make it easy to overload
curl_es $espod /_cluster/settings -XPUT -d '{
    "transient" : {
        "threadpool.bulk.queue_size" : 1,
        "threadpool.bulk.size": 1
    }
}' | jq . | artifact_out

# check settings
curl_es $espod /_cat/thread_pool?v\&h=bc,br,ba,bq,bs | artifact_out

# create a really large bulk index request json file:
bulktestjson=$( mktemp )
python -c 'import sys
for ii in xrange(0,int(sys.argv[1])):
    print """
{{"index":{{"_index":"bulkindextest","_type":"bulkindextest"}}}}
{{"field0":"value value value {0}"}}
""".format(ii)
' 100000 > $bulktestjson
wc $bulktestjson | artifact_out
ls -al $bulktestjson | artifact_out

# start curl doing many bulk index ops
bulkdonefile=$( mktemp )
echo $bulkdonefile | artifact_out
do_curl_bulk_index() {
    local parallel_curls=6
    local ii
    local bulkpids=""
    for ii in $( seq 1 $parallel_curls ) ; do
        while [ ! -s $bulkdonefile -a -n "${bulktestjson:-}" -a -f "${bulktestjson:-}" ] ; do
            cat $bulktestjson | curl_es_input $espod /_bulk -XPOST --data-binary @- > /dev/null
        done & bulkpids="$bulkpids $!"
    done
    curl_es $espod /_cat/thread_pool?v\&h=bc,br,ba,bq,bs | artifact_out
    wait $bulkpids
    curl_es $espod /_cat/thread_pool?v\&h=bc,br,ba,bq,bs | artifact_out
}

do_curl_bulk_index & curlpid=$!
# wait for elasticsearch to report bulk index rejections
os::cmd::try_until_not_text "curl_es $espod /_cat/thread_pool?h=br" "^0\$"

# restart fluentd to make sure the logs are clear
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
oc delete pod --force $fpod
os::cmd::try_until_failure "oc describe pod $fpod"
sleep 1
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )

# wait for BulkIndexQueueFull errors in fluentd log
flog=/var/log/fluentd.log
os::cmd::try_until_success "grep -q BulkIndexQueueFull /var/log/fluentd.log" $(( 300 * second ))

# write some messages
uuid_es=$( openssl rand -hex 64 )
uuid_es_ops=$( openssl rand -hex 64 )

wait_for_fluentd_ready
count=40
countops=500
os::log::info Adding $count project log records and $countops operations log records . . .
starttime=$( date +%s )
# not sure why, but it seems the operations messages get sent
# to es much faster - so add more of them to see if we can get
# them to be rejected
for jj in $( seq 1 $count ) ; do
    add_test_message "$uuid_es-$jj"
    os::log::debug added es message $uuid_es-$jj
done

opsloglines=$( mktemp )
python -c 'import sys
for ii in xrange(1,int(sys.argv[1])+1):
    print "{0}-{1}".format(sys.argv[2], ii)
' $countops $uuid_es_ops > $opsloglines
logger -i -p local6.info -t $uuid_es_ops -f $opsloglines
os::log::debug added es-ops message $uuid_es_ops-$jj
rm -f $opsloglines

os::log::info Finished adding $count project and $countops operation log records

fullmsg="GET /${uuid_es}-"
qs='{"query":{"match_phrase":{"message":"'"${fullmsg}"'"}}}'
firstcount=$( curl_es ${espod} /project.${LOGGING_NS}.*/_count -X POST -d "$qs" | get_count_from_json )
if [ "${firstcount:-0}" -eq $count ] ; then
    os::log::warning All project records added - some should have been queued due to bulk index rejection
else
    os::log::info Found $firstcount of $count project records in Elasticsearch
fi
qsops='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${uuid_es_ops}"'"}}}'
firstcount=$( curl_es ${esopspod} /.operations.*/_count -X POST -d "$qsops" | get_count_from_json )
if [ "${firstcount:-0}" -eq $countops ] ; then
    os::log::warning All operations records added - some should have been queued due to bulk index rejection
else
    os::log::info Found $firstcount of $countops operations records in Elasticsearch
fi

#curl_es ${esopspod} "/.operations.*/_search?q=systemd.u.SYSLOG_IDENTIFIER:$uuid_es_ops&sort=@timestamp:asc&size=1" | jq .
#curl_es ${esopspod} "/.operations.*/_search?q=systemd.u.SYSLOG_IDENTIFIER:$uuid_es_ops&sort=@timestamp:desc&size=1" | jq .

# shutdown the do_curl_bulk_index
echo done > $bulkdonefile
wait $curlpid
endtime=$( date +%s )

# check the logs to see if there are bulk index rejection errors between starttime and endtime
found=
founderr=0
foundsuc=0
lasterr=
lastsuc=
while read datestr timestr tz logline ; do
    iserr=
    if echo "$logline" | grep -q 'Fluent::ElasticsearchErrorHandler::BulkIndexQueueFull' ; then
        founderr=$( expr $founderr + 1 )
        iserr=1
    elif echo "$logline" | grep -q 'retry succeeded.' ; then
        foundsuc=$( expr $foundsuc + 1 )
    else
        continue
    fi
    dt=$( date --date="$datestr $timestr $tz" +%s )
    if [ -n "$dt" -a "$dt" -ge $starttime -a "$dt" -le $endtime ] ; then
        if [ -n "${iserr:-}" ] ; then
            found=1
            os::log::debug "Found a BulkIndexQueueFull error during test run: $datestr $timestr $tz $logline"
            lasterr=$dt
        else
            lastsuc=$dt
        fi
    fi
done < $flog

if [ -z "${found:-}" ] ; then
    os::log::error There were no bulk index errors recorded by fluentd during the test run between $( date --date=@$starttime ) and $( date --date=@$endtime )
    exit 1
fi

os::log::info There were $founderr bulk index errors and $foundsuc successful retries recorded by fluentd during the test run between $( date --date=@$starttime ) and $( date --date=@$endtime )

if [ -z "$lastsuc" ] ; then
    os::log::info There were no successful retries during the test run between $( date --date=@$starttime ) and $( date --date=@$endtime )
elif [ $lasterr -lt $lastsuc ] ; then
    os::log::info Last successful retry at $( date --date=@$lastsuc ) was after last error at $( date --date=@$lasterr )
else
    os::log::info Last error at $( date --date=@$lasterr ) was at or after last successful retry at $( date --date=@$lastsuc )
fi

rc=0
timeout=$(( 180 * second ))
# duplicates can be added when bulk ops are retried, so greater than or equal
if os::cmd::try_until_success "curl_es ${espod} /project.${LOGGING_NS}.*/_count -X POST -d '$qs' | jq '.count >= ${count}'" $timeout ; then
    os::log::debug good - found $count record project ${LOGGING_NS} for \'$fullmsg\'
else
    os::log::error not found $count record project ${LOGGING_NS} for \'$fullmsg\' after timeout
    os::log::debug "$( curl_es ${espod} /project.${LOGGING_NS}.*/_search -X POST -d "$qs" )"
    os::log::error "Checking journal for '$fullmsg' ..."
    if sudo journalctl | grep -q "$fullmsg" ; then
        os::log::error "Found '$fullmsg' in journal"
        os::log::debug "$( sudo journalctl | grep "$fullmsg" )"
    elif sudo grep -q "$fullmsg" /var/log/containers/* ; then
        os::log::error "Found '$fullmsg' in /var/log/containers/*"
        os::log::debug "$( sudo grep -q "$fullmsg" /var/log/containers/* )"
    else
        os::log::error "Unable to find '$fullmsg' in journal or /var/log/containers/*"
    fi

    rc=1
fi

if os::cmd::try_until_success "curl_es ${esopspod} /.operations.*/_count -X POST -d '$qsops' | jq '.count >= ${countops}'" $timeout ; then
    os::log::debug good - found $countops record project .operations for $uuid_es_ops
else
    os::log::error not found $countops record project .operations for $uuid_es_ops after timeout
    os::log::debug "$( curl_es ${esopspod} /.operations.*/_search -X POST -d "$qsops" )"
    os::log::error "Checking journal for $uuid_es_ops..."
    if sudo journalctl | grep -q $uuid_es_ops ; then
        os::log::error "Found $uuid_es_ops in journal"
        os::log::debug "$( sudo journalctl | grep $uuid_es_ops )"
    else
        os::log::error "Unable to find $uuid_es_ops in journal"
    fi
    rc=1
fi

exit $rc

#!/bin/bash

# test bulk rejection handling
source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
trap os::test::junit::reconcile_output EXIT
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/bulk_rejection"

LOGGING_NS=${LOGGING_NS:-openshift-logging}
esopsdc=$( get_es_dcs es-ops )
if [ -z "${esopsdc}" ] ; then
    esopsdc=$( get_es_dcs es )
fi

keyname=threadpool
es_ver=$( get_es_major_ver )
if [ "${es_ver:-2}" -gt 2 ] ; then
    keyname=thread_pool
fi

function cleanup() {
    local result_code="$?"
    set +e
    if [ -n "${bulkdonefile:-}" ] ; then
        echo done > $bulkdonefile
    fi
    if [ -n "${bulktestjson:-}" -a -f "${bulktestjson:-}" ] ; then
        rm -f $bulktestjson
    fi
    curl_es $esopssvc /bulkindextest -XDELETE | jq . | artifact_out
    fpod=$( get_running_pod fluentd )
    if [ -f /var/log/fluentd.log ] ; then
        cp /var/log/fluentd.log $ARTIFACT_DIR/fluentd-with-bulk-index-rejections.log
    else
        oc logs $fpod > $ARTIFACT_DIR/fluentd-with-bulk-index-rejections.log
    fi
    if [ -n "${es_cm:-}" -a -f "${es_cm:-}" ] ; then
        oc replace --force -f $es_cm 2>&1 | tee artifact_out
    fi
    if [ -n "${esopsdc:-}" ] ; then
        oc rollout latest $esopsdc 2>&1 | tee artifact_out
        oc rollout status -w $esopsdc 2>&1 | tee artifact_out
        # have to get esopssvc again if needed
    fi
    if [ -n "${f_cm:-}" -a -f "${f_cm:-}" ] ; then
        oc replace --force -f $f_cm
    fi
    if [ -n "${f_ds:-}" -a -f "${f_ds:-}" ] ; then
        oc replace --force -f $f_ds
    fi
    os::cmd::try_until_failure "oc get pod $fpod"
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

# save current es settings
es_cm=$( mktemp )
oc get cm/logging-elasticsearch -o yaml > $es_cm

# thanks es5 - https://www.elastic.co/guide/en/elasticsearch/reference/5.1/breaking_50_settings_changes.html#_threadpool_settings
# change queue size and pool size to make it easy to hit limit
oc get cm/logging-elasticsearch -o yaml | \
    sed '/^  elasticsearch.yml/a\
    '$keyname':\
      bulk:\
        queue_size: 1\
        size: 1' | oc replace --force -f - 2>&1 | artifact_out

oc rollout latest $esopsdc 2>&1 | artifact_out
oc rollout status -w $esopsdc 2>&1 | artifact_out
essvc=$( get_es_svc es )
esopssvc=$( get_es_svc es-ops )
esopssvc=${esopssvc:-$essvc}

# check settings
bulk_url=$( get_bulk_thread_pool_url $es_ver "v" c r a q s qs )
curl_es $esopssvc "${bulk_url}" 2>&1 | artifact_out
# save current fluentd settings
f_cm=$( mktemp )
f_ds=$( mktemp )

oc get cm/logging-fluentd -o yaml > $f_cm
oc get ds/logging-fluentd -o yaml > $f_ds

# stop fluentd to make sure the logs are clear
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
os::cmd::expect_success "oc label node --all logging-infra-fluentd-"
os::cmd::try_until_failure "oc get pod $fpod"

# turn on debug output
cat $f_cm | \
    sed -e 's,@include configs.d/openshift/system.conf,<system>\
      log_level debug\
    </system>,' | oc replace --force -f -

oc set env ds/logging-fluentd DEBUG=true

# the -r is because some tests create subdirs of this
sudo rm -rf /var/lib/fluentd/*
sudo rm -f /var/log/journal.pos

os::cmd::expect_success "oc label node --all logging-infra-fluentd=true"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
wait_for_fluentd_ready
fpod=$( get_running_pod fluentd )

# wait for fluentd to get up and running
sleep 15

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
            cat $bulktestjson | curl_es_input $esopssvc /_bulk -XPOST --data-binary @- > /dev/null
        done & bulkpids="$bulkpids $!"
    done
    curl_es $esopssvc "${bulk_url}" 2>&1 | artifact_out
    wait $bulkpids
    curl_es $esopssvc "${bulk_url}" 2>&1 | artifact_out
}

do_curl_bulk_index & curlpid=$!
# wait for elasticsearch to report bulk index rejections
bulk_reject_url=$( get_bulk_thread_pool_url $es_ver "" r )
os::cmd::try_until_not_text "curl_es $esopssvc ${bulk_reject_url}" "^0\$"
start_bulk_rejections=$( curl_es $esopssvc ${bulk_reject_url} )

# write some messages
uuid_es_ops=$( openssl rand -hex 64 )
countops=500
os::log::info Adding $countops operations log records . . .
# not sure why, but it seems the operations messages get sent
# to es much faster - so add more of them to see if we can get
# them to be rejected

opsloglines=$( mktemp )
python -c 'import sys
for ii in xrange(1,int(sys.argv[1])+1):
    print "{0}-{1}".format(sys.argv[2], ii)
' $countops $uuid_es_ops > $opsloglines
starttime=$( date +%s )
logger -i -p local6.info -t $uuid_es_ops -f $opsloglines
rm -f $opsloglines

os::log::info Finished adding $countops operation log records

qsops='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${uuid_es_ops}"'"}}}'
firstcount=$( curl_es ${esopssvc} /.operations.*/_count -X POST -d "$qsops" | get_count_from_json )
if [ "${firstcount:-0}" -eq $countops ] ; then
    os::log::warning All operations records added - some should have been queued due to bulk index rejection
else
    os::log::info Found $firstcount of $countops operations records in Elasticsearch
fi

#curl_es ${esopssvc} "/.operations.*/_search?q=systemd.u.SYSLOG_IDENTIFIER:$uuid_es_ops&sort=@timestamp:asc&size=1" | jq .
#curl_es ${esopssvc} "/.operations.*/_search?q=systemd.u.SYSLOG_IDENTIFIER:$uuid_es_ops&sort=@timestamp:desc&size=1" | jq .

# shutdown the do_curl_bulk_index
echo done > $bulkdonefile
wait $curlpid
endtime=$( date +%s )
end_bulk_rejections=$( curl_es $esopssvc ${bulk_reject_url} )

if ! os::cmd::expect_success "test ${start_bulk_rejections} -lt ${end_bulk_rejections}" ; then
    os::log::warning No bulk rejections reported between $( date --date=@$starttime ) and $( date --date=@$endtime )
fi

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
done < /var/log/fluentd.log

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
if os::cmd::try_until_success "curl_es ${esopssvc} /.operations.*/_count -X POST -d '$qsops' | jq '.count == ${countops}'" $timeout ; then
    os::log::debug good - found $countops record project .operations for $uuid_es_ops
else
    os::log::error not found $countops record project .operations for $uuid_es_ops after timeout
    os::log::debug "$( curl_es ${esopssvc} /.operations.*/_search -X POST -d "$qsops" )"
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

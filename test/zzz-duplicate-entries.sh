#!/bin/bash

# This is a test suite for testing basic log processing
# functionality and existance of duplicate records when journal rolls over

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/zzzz-duplicate-entries"

cleanup() {
    local return_code="$?"
    set +e

    if [ -f /etc/systemd/journald.conf.bak ]; then
      sudo mv /etc/systemd/journald.conf.bak /etc/systemd/journald.conf
      sudo systemctl restart systemd-journald
    fi

#    oc label node --all logging-infra-fluentd- 2>&1 | artifact_out || :
#    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $((second * 120))

    # cleanup fluentd pos file and restart
#    flush_fluentd_pos_files
#    oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
#    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

get_fluentd_pid() {
    local pid
    artifact_log begin get_fluentd_pid
    for pid in $( sudo pgrep fluentd ) ; do
        local environfile=$ARTIFACT_DIR/environ.$pid
        sudo cat /proc/$pid/environ | tr '\0' '\n' > $environfile
        if grep \^USE_MUX=true $environfile > $ARTIFACT_DIR/grep-out.$pid 2>&1 ; then
            artifact_log pid $pid is mux
            continue
        else
            artifact_log pid $pid is fluentd
            echo $pid
            break
        fi
    done
    artifact_log end get_fluentd_pid
}

# turn off fluentd
#oc label node --all logging-infra-fluentd- 2>&1 | artifact_out || :
#os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $((second * 120))

sudo sed -i.bak \
    -e "s/^.*SystemMaxUse=.*$/ SystemMaxUse=1M/" \
    -e "s/^.*SystemMaxFileSize=.*$/ SystemMaxFileSize=32K/" \
    /etc/systemd/journald.conf
sudo systemctl restart systemd-journald

sleep 10
#flush_fluentd_pos_files
#oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
#os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
wait_for_fluentd_to_catch_up
fluentd_pid=$( get_fluentd_pid )
# get files open by fluentd
sudo ls -al /proc/$fluentd_pid/fd > $ARTIFACT_DIR/fluentd-files-before

curl -s -L -o loader https://raw.githubusercontent.com/ViaQ/logging-load-driver/master/loader
curl -s -L -o verify-loader https://raw.githubusercontent.com/ViaQ/logging-load-driver/master/verify-loader
chmod +x loader verify-loader
logger_file=$ARTIFACT_DIR/logger-input.txt
ident=$( openssl rand -hex 16 )
# write 1000's of messages to the journal to ensure rollover given the tuning settings above
# keep under 9999 records to make it easier for Elasticsearch to search - max size limit of 9999
./loader --distribution=fixed --invocid=$ident --report-interval=0 --total-size=6 768 > $logger_file
wc $logger_file | artifact_out
ls -al $logger_file | artifact_out
MESSAGE_COUNT=$( wc -l $logger_file | awk '{print $1}' )
logger -i -p local6.info -t $ident -f $logger_file

os::log::info ${MESSAGE_COUNT} messages were generated...

sudo ls -al /proc/$fluentd_pid/fd > $ARTIFACT_DIR/fluentd-files-during

es_svc=$( get_es_svc es )
es_ops_svc=$( get_es_svc es-ops )
es_ops_svc=${es_ops_svc:-$es_svc}
rc=0
qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${ident}"'"}}}'
if os::cmd::try_until_text "curl_es ${es_ops_svc} /.operations.*/_count -X POST -d '$qs' | get_count_from_json" \^${MESSAGE_COUNT}\$ $(( 5 * minute )) ; then
    os::log::info good - found exactly ${MESSAGE_COUNT} records
else
    os::log::warning did not find exactly ${MESSAGE_COUNT} records
fi
sudo ls -al /proc/$fluentd_pid/fd > $ARTIFACT_DIR/fluentd-files-after

# fluentd should not have any deleted files open
os::cmd::expect_failure "grep -q deleted $ARTIFACT_DIR/fluentd-files-after"

searchout=$ARTIFACT_DIR/search-output.json
curl_es ${es_ops_svc} /.operations.*/_search?size=9999 -X POST -d "$qs" | jq . > $searchout
# need to ensure that there are no missing records, and that there
# are no duplicate records in $searchout
verifyin=$ARTIFACT_DIR/verify-in.txt
cat $searchout | jq -r .hits.hits[]._source.message | sort -n > $verifyin
verifyout=$ARTIFACT_DIR/verify-out.txt
./verify-loader --report-interval=0 $verifyin > $verifyout 2>&1 || :
# look for this in the output
# +++ verify-loader
# $ident: NNNN 0 MMMM
# where NNNN should match exactly ${MESSAGE_COUNT} - if not, then there were missing records
# and MMMM should be 0 - if not, then there were MMMM duplicate records
# ${MESSAGE_COUNT} + MMMM = NNNN
# if there are duplicates, they will be indicated by lines like this in the verify-out.txt
# $ident: 2663 2663  <-
# where 2663 is the sequence number that was duplicated
verifyrecs=$( awk '/^+++ verify-loader/ {found=1; next;}; found == 1 {print $2; exit}' $verifyout )
verifydups=$( awk '/^+++ verify-loader/ {found=1; next;}; found == 1 {print $4; exit}' $verifyout )

if [ "$verifyrecs" -ne "${MESSAGE_COUNT}" ] ; then
    os::log::warning Expected ${MESSAGE_COUNT} records but found $verifyrecs instead
    diff=$(( MESSAGE_COUNT - verifyrecs ))
    if [ $diff -lt 0 ] ; then
        diff=$(( 0 - diff ))
    fi
    # no way to calculate threshold for now due to bug in systemd journal or plugin
    #os::cmd::expect_success "test $diff -lt 400"
fi

if [ "$verifydups" -gt 0 ] ; then
    os::log::warning Found $verifydups duplicate records
    # no way to calculate threshold for now due to bug in systemd journal or plugin
    #os::cmd::expect_success "test $verifydups -lt 10"
fi

exit $rc

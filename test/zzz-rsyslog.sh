#!/bin/bash

# This is a test suite for testing basic log processing
# functionality and Kubernetes processing for rsyslog

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/zzz-rsyslog"

artifact_log Unit tests for undefined_field
pushd ${OS_O_A_L_DIR}/rsyslog/undefined_field > /dev/null
cp undefined_field.go $ARTIFACT_DIR || :
cp undefined_field_test.go $ARTIFACT_DIR || :
go test -v 2>&1 | artifact_out
popd > /dev/null
artifact_log Unit tests for rsyslog_exporter
pushd ${OS_O_A_L_DIR}/rsyslog/go/src/github.com/soundcloud/rsyslog_exporter > /dev/null
go test -v 2>&1 | artifact_out
popd > /dev/null

LOGGING_NS=${LOGGING_NS:-openshift-logging}
es_pod=$( get_es_pod es )
es_ops_pod=$( get_es_pod es-ops )
es_ops_pod=${es_ops_pod:-$es_pod}

clear_and_restart_journal() {
    oal_sudo journalctl --vacuum-size=$( expr 1024 \* 1024 \* 2 ) 2>&1 | artifact_out
    oal_sudo systemctl restart systemd-journald 2>&1 | artifact_out
}

if oc get clusterlogging instance > /dev/null 2>&1 ; then
    deployfunc=deploy_using_operators
    clear_and_restart_journal() { : ; }
elif [ "${USE_RSYSLOG_RPMS:-false}" = true ] ; then
    rsyslog_service=rsyslog
    extra_ansible_evars=""
    deployfunc=deploy_using_ansible
    rsyslog__config_dir="/etc/rsyslog.d"
else
    rsyslog_service=rsyslog-container
    extra_ansible_evars="-e use_rsyslog_image=True"
    deployfunc=deploy_using_ansible
    rsyslog__config_dir="/etc/rsyslog.d"
fi

# clear the journal
clear_and_restart_journal

cleanup() {
    local return_code="$?"
    set +e
    get_all_logging_pod_logs
    oc get cm rsyslog -o yaml > $ARTIFACT_DIR/rsyslog_configmap.yaml 2>&1
    oc get cm rsyslog-bin -o yaml > $ARTIFACT_DIR/rsyslog.sh 2>&1
    if [ "deploy_using_ansible" = "$deployfunc" ] ; then
        if [ -n "${tmpinv:-}" -a -f "${tmpinv:-}" ] ; then
            rm -f $tmpinv
        fi
        oal_sudo journalctl -m -u $rsyslog_service --since="-1hour" > $ARTIFACT_DIR/rsyslog-rsyslog.log 2>&1
        if [ -n "${rsyslog_save}" -a -d "${rsyslog_save}" ] ; then
            oal_sudo rm -rf ${rsyslog__config_dir}/*
            oal_sudo cp -p ${rsyslog_save}/* ${rsyslog__config_dir} || :
            rm -rf ${rsyslog_save}
            oal_sudo systemctl restart $rsyslog_service
        fi
        # cleanup fluentd pos file and restart
        start_fluentd true 2>&1 | artifact_out
    else
        rpod=$( get_running_pod rsyslog )
        oc exec $rpod -c rsyslog -- env > $ARTIFACT_DIR/rsyslog_env.txt 2>&1 || :
        oc exec $rpod -c rsyslog -- cat /var/log/rsyslog/rsyslog_debug.log > $ARTIFACT_DIR/rsyslog_debug.log 2>&1 || :
        oc get clusterlogging instance -o yaml > $ARTIFACT_DIR/clinstance.yaml 2>&1
        oc describe deploy cluster-logging-operator > $ARTIFACT_DIR/deploy.clo.yaml 2>&1
        oc describe ds rsyslog > $ARTIFACT_DIR/ds.rsyslog.yaml 2>&1
        oc get secret > $ARTIFACT_DIR/secrets 2>&1
        oc get svc > $ARTIFACT_DIR/services 2>&1
        oc get svc rsyslog -o yaml > $ARTIFACT_DIR/rsyslog.svc.yaml 2>&1 || :
        oc patch clusterlogging instance --type=json \
            --patch '[{"op":"replace","path":"/spec/collection/logs/type","value":"fluentd"}]' 2>&1 | artifact_out
        enable_cluster_logging_operator
        oc label node --all logging-infra-rsyslog-
        os::cmd::try_until_failure "oc get pods $rpod > /dev/null 2>&1"
        start_fluentd true 2>&1 | artifact_out
        disable_cluster_logging_operator
        sleep 10
        oc get secret > $ARTIFACT_DIR/secrets.after 2>&1
    fi

    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

deploy_using_ansible() {
    rsyslog_save=$( mktemp -d )
    oal_sudo cp -p ${rsyslog__config_dir}/* ${rsyslog_save} || :
    pushd $OS_O_A_L_DIR/hack/testing/rsyslog > /dev/null
    tmpinv=$( mktemp )
    cat > $tmpinv <<EOF
[masters]
localhost ansible_ssh_user=${RSYSLOG_ANSIBLE_SSH_USER:-ec2-user} openshift_logging_use_ops=$use_es_ops

[nodes]
localhost ansible_ssh_user=${RSYSLOG_ANSIBLE_SSH_USER:-ec2-user} openshift_logging_use_ops=$use_es_ops
EOF

    tmpvars=$( mktemp )
    cat > $tmpvars <<EOF
rsyslog__enabled: true
# install viaq packages & config files
rsyslog__viaq: true
rsyslog__capabilities: [ 'viaq', 'viaq-k8s' ]
rsyslog__group: root
rsyslog__user: root
# to share rsyslog__config_dir with roles/openshift_logging_rsyslog
rsyslog__config_dir: /etc/rsyslog.d
rsyslog__viaq_config_dir: "{{rsyslog__config_dir}}/viaq"
rsyslog__system_log_dir: /var/log
rsyslog__work_dir: /var/lib/rsyslog
use_omelastcsearch_cert: True
logging_mmk8s_token: "{{rsyslog__viaq_config_dir}}/mmk8s.token"
logging_mmk8s_ca_cert: "{{rsyslog__viaq_config_dir}}/mmk8s.ca.crt"
logging_elasticsearch_ca_cert: "{{rsyslog__viaq_config_dir}}/es-ca.crt"
logging_elasticsearch_cert: "{{rsyslog__viaq_config_dir}}/es-cert.pem"
logging_elasticsearch_key: "{{rsyslog__viaq_config_dir}}/es-key.pem"
EOF

    os::cmd::expect_success "ansible-playbook -vvv -e@$tmpvars --become --become-user root --connection local \
        $extra_ansible_evars -i $tmpinv playbook.yaml > $ARTIFACT_DIR/zzz-rsyslog-ansible.log 2>&1"
    mv $tmpinv $ARTIFACT_DIR/inventory_file
    mv $tmpvars $ARTIFACT_DIR/vars_file

    popd > /dev/null

    pushd /etc
    oal_sudo tar cf - rsyslog.conf rsyslog.d | (cd $ARTIFACT_DIR; tar xf -)
    popd > /dev/null
    oal_sudo systemctl stop $rsyslog_service
    # make test run faster by resetting journal cursor to "now"
    oal_sudo journalctl -m -n 1 --show-cursor | awk '/^-- cursor/ {printf("%s",$3)}' | oal_sudo tee /var/lib/rsyslog/imjournal.state > /dev/null
    oal_sudo systemctl start $rsyslog_service
}

deploy_using_operators() {
    # edit the operator - change logcollector type to rsyslog
    oc label node -l logging-ci-test=true --overwrite logging-infra-rsyslog=true 2>&1 | artifact_out
    oc patch clusterlogging instance --type=json \
        --patch '[{"op":"replace","path":"/spec/collection/logs/type","value":"rsyslog"}]' 2>&1 | artifact_out
    enable_cluster_logging_operator
    os::cmd::try_until_success "oc get pods 2> /dev/null | grep -q 'rsyslog.*Running'" $(( 10 * minute ))
    rpod=$( get_running_pod rsyslog )
    disable_cluster_logging_operator
    sleep 10
    os::cmd::try_until_success "oc get cm rsyslog 2> /dev/null"
    stop_rsyslog $rpod
    oc set env $rsyslog_ds RSYSLOG_JOURNAL_READ_FROM_TAIL=on RSYSLOG_FILE_READ_FROM_TAIL=on RSYSLOG_USE_IMPSTATS_FILE=true
    # enable annotation_match
    oc get cm rsyslog -o yaml | \
      sed -e 's/action(type="mmkubernetes"/action(type="mmkubernetes" annotation_match=["."]/' | \
      oc replace --force -f - 2>&1 | artifact_out
    start_rsyslog cleanfirst
    rpod=$( get_running_pod rsyslog )
}

get_logmessage() {
    logmessage="$1"
    cp $2 $ARTIFACT_DIR/zzz-rsyslog-record.json
}
get_logmessage2() {
    logmessage2="$1"
    cp $2 $ARTIFACT_DIR/zzz-rsyslog-record-ops.json
}

# turn off fluentd
stop_fluentd "" $((second * 120)) 2>&1 | artifact_out

if [ $es_pod = $es_ops_pod ] ; then
    use_es_ops=False
else
    use_es_ops=True
fi

$deployfunc
# Set kubernetes to CDM_KEEP_EMPTY_FIELDS to keep "openshift_io/node-selector": "" in
# kubernetes.namespace_annotations.openshift_io/node-selector
oc set env $rsyslog_ds CDM_KEEP_EMPTY_FIELDS="kubernetes"
start_rsyslog

sleep 10
wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
proj=$ARTIFACT_DIR/zzz-rsyslog-record.json
ops=$ARTIFACT_DIR/zzz-rsyslog-record-ops.json

# make sure record is coming from rsyslog
actual_pipeline=$( cat $proj | jq -r .hits.hits[0]._source.pipeline_metadata.collector.name )
os::cmd::expect_success "test $actual_pipeline = rsyslog"

# see if the kubernetes metadata matches
actual_pod_name=$( cat $proj | jq -r .hits.hits[0]._source.kubernetes.pod_name )
actual_ns_name=$( cat $proj | jq -r .hits.hits[0]._source.kubernetes.namespace_name )
actual_pod_id=$( cat $proj | jq -r .hits.hits[0]._source.kubernetes.pod_id )
actual_ns_id=$( cat $proj | jq -r .hits.hits[0]._source.kubernetes.namespace_id )
actual_pod_host=$( cat $proj | jq -r .hits.hits[0]._source.kubernetes.host )
os::cmd::expect_success "test $actual_pod_id = $( oc get pod $actual_pod_name -o jsonpath='{.metadata.uid}' )"
os::cmd::expect_success "test $actual_pod_host = $( oc get pod $actual_pod_name -o jsonpath='{.spec.nodeName}' )"
os::cmd::expect_success "test $actual_ns_id = $( oc get project $actual_ns_name -o jsonpath='{.metadata.uid}' )"
oc get pod $actual_pod_name -o json | jq -S .metadata.labels | \
    jq 'with_entries(.key |= gsub("[.]";"_"))' > $ARTIFACT_DIR/zzz-rsyslog-expected-labels.json
cat $proj | jq -S '.hits.hits[0]._source.kubernetes.labels' > $ARTIFACT_DIR/zzz-rsyslog-actual-labels.json
os::cmd::expect_success "diff $ARTIFACT_DIR/zzz-rsyslog-expected-labels.json $ARTIFACT_DIR/zzz-rsyslog-actual-labels.json"

oc get pod $actual_pod_name -o json | jq -S .metadata.annotations | \
    jq 'with_entries(.key |= gsub("[.]";"_"))' > $ARTIFACT_DIR/zzz-rsyslog-expected-annotations.json
cat $proj | jq -S '.hits.hits[0]._source.kubernetes.annotations' > $ARTIFACT_DIR/zzz-rsyslog-actual-annotations.json
os::cmd::expect_success "diff $ARTIFACT_DIR/zzz-rsyslog-expected-annotations.json $ARTIFACT_DIR/zzz-rsyslog-actual-annotations.json"

if [ -n "$( oc get project $actual_ns_name -o jsonpath='{.metadata.labels}')" ] ; then
    oc get project $actual_ns_name -o json | jq -S .metadata.labels | \
        jq 'with_entries(.key |= gsub("[.]";"_"))' > $ARTIFACT_DIR/zzz-rsyslog-expected-nslabels.json
    cat $proj | jq -S '.hits.hits[0]._source.kubernetes.namespace_labels' > $ARTIFACT_DIR/zzz-rsyslog-actual-nslabels.json
    os::cmd::expect_success "diff $ARTIFACT_DIR/zzz-rsyslog-expected-nslabels.json $ARTIFACT_DIR/zzz-rsyslog-actual-nslabels.json"
else
    os::cmd::expect_success_and_text "cat $proj | jq -r .hits.hits[0]._source.kubernetes.namespace_labels" "^null\$"
fi

if [ -n "$( oc get project $actual_ns_name -o jsonpath='{.metadata.annotations}')" ] ; then
    oc get project $actual_ns_name -o json | jq -S .metadata.annotations | \
        jq 'with_entries(.key |= gsub("[.]";"_"))' > $ARTIFACT_DIR/zzz-rsyslog-expected-nsannotations.json
    cat $proj | jq -S '.hits.hits[0]._source.kubernetes.namespace_annotations' > $ARTIFACT_DIR/zzz-rsyslog-actual-nsannotations.json
    os::cmd::expect_success "diff $ARTIFACT_DIR/zzz-rsyslog-expected-nsannotations.json $ARTIFACT_DIR/zzz-rsyslog-actual-nsannotations.json"
else
    os::cmd::expect_success_and_text "cat $proj | jq -r .hits.hits[0]._source.kubernetes.namespace_annotations" "^null\$"
fi

# see if ops fields are present
# make sure record is coming from rsyslog
actual_pipeline=$( cat $ops | jq -r .hits.hits[0]._source.pipeline_metadata.collector.name )
os::cmd::expect_success "test $actual_pipeline = rsyslog"

os::cmd::expect_success_and_not_text "cat $ops | jq -r .hits.hits[0]._source.systemd.t.TRANSPORT" "^null$"
os::cmd::expect_success_and_not_text "cat $ops | jq -r .hits.hits[0]._source.systemd.t.SELINUX_CONTEXT" "^null$"
os::cmd::expect_success_and_not_text "cat $ops | jq -r .hits.hits[0]._source.systemd.u.SYSLOG_FACILITY" "^null$"
os::cmd::expect_success_and_not_text "cat $ops | jq -r .hits.hits[0]._source.systemd.u.SYSLOG_PID" "^null$"
os::cmd::expect_success_and_text "cat $ops | jq -r .hits.hits[0]._source.message" "^${logmessage2}\$"
os::cmd::expect_success_and_not_text "cat $ops | jq -r .hits.hits[0]._source.level" "^null$"
os::cmd::expect_success_and_not_text "cat $ops | jq -r .hits.hits[0]._source.hostname" "^null$"
ts=$( cat $ops | jq -r '.hits.hits[0]._source."@timestamp"' )
os::cmd::expect_success "test ${ts} != null"

# Unset CDM_KEEP_EMPTY_FIELDS
oc set env $rsyslog_ds CDM_KEEP_EMPTY_FIELDS-
start_rsyslog

# see if the prometheus exporter is working
rpod="$( get_running_pod rsyslog )"
rpod_ip="$( oc get pod ${rpod} -o jsonpath='{.status.podIP}' )"

os::cmd::try_until_success "curl -s -k https://${rpod_ip}:24231/metrics"
curl -s -k https://${rpod_ip}:24231/metrics > $ARTIFACT_DIR/${rpod}-metrics-scrape 2>&1

# Test logrotation (LOG400) - OKD 4.2 and above
# check rsyslog logs
rpod=$( get_running_pod rsyslog )
oc logs $rpod -c rsyslog > $ARTIFACT_DIR/rsyslog.log 2>&1
oc exec $rpod -c rsyslog -- ls -l /var/log/rsyslog/rsyslog.log > $ARTIFACT_DIR/rsyslog.exec.txt 2>&1
oc exec $rpod -c rsyslog -- cat /var/log/rsyslog/rsyslog.log >> $ARTIFACT_DIR/rsyslog.exec.txt 2>&1
os::cmd::expect_success_and_text "oc logs $rpod -c rsyslog | grep 'oc exec <pod_name> -- logs'" "^oc exec .pod_name. -- logs$"
os::cmd::expect_success "oc exec $rpod -c rsyslog -- ls /var/log/rsyslog/rsyslog.log > /dev/null 2>&1"
logsize=$( oc exec $rpod -c rsyslog -- wc -c /var/log/rsyslog/rsyslog.log | awk '{print $1}' )

# Check if logrotate works as expected
if [ $logsize -gt 0 ]; then
    # set max log file count and max log size
    maxcount=3
    maxsize=$( expr $logsize / $maxcount )

    # run logrotate every minute for testing
    savecm=$( mktemp )
    workcm=$( mktemp )
    oc get configmap logrotate-crontab -o yaml > $savecm
    cat $savecm | sed -e 's,\([ ]*\)[0-9]* .* \(root[ 	]*/usr/bin/bash[ 	]*/opt/app-root/bin/logrotate.*.sh\),\1* * * * *       \2,' > $workcm
    cp $savecm $ARTIFACT_DIR/logrotate-crontab.orig.yaml
    cp $workcm $ARTIFACT_DIR/logrotate-crontab.yaml
    if [ -s $workcm ]; then
        oc apply --force -f $workcm
    else
        artifact_log WARNING generated logrotate-crontab is empty.
    fi
    # see what the rsyslog file and log dir look like before rotation
    artifact_log logs before rotation
    oc exec $rpod -c rsyslog -- ls -l /var/log/rsyslog/ | artifact_out
    oc exec $rpod -c rsyslog -- cat /var/log/rsyslog/rsyslog.log > $ARTIFACT_DIR/rsyslog-before-rotation.log
    stop_rsyslog $rpod
    oc set env $rsyslog_ds LOGGING_FILE_SIZE=$maxsize LOGGING_FILE_AGE=$maxcount
    start_rsyslog

    # wait longer than ($maxcount + 1) * 60 seconds.
    sleep $( expr $( expr $maxcount + 1 ) \* 60 )
    rpod=$( get_running_pod rsyslog )
    filecount=$( oc exec $rpod -c rsyslog -- ls -l /var/log/rsyslog/ | grep rsyslog.log- | wc -l )
    filesize=$( oc exec $rpod -c rsyslog -- ls -l /var/log/rsyslog/ | grep "rsyslog.log$" | awk '{print $5}' )
    artifact_log "logrotate crontab"
    oc exec $rpod -c logrotate -- /usr/bin/cat /etc/cron.d/logrotate 2>&1 | artifact_out
    artifact_log "=========="
    artifact_log "logrotate scripts"
    oc exec $rpod -c logrotate -- /usr/bin/cat /opt/app-root/bin/logrotate.sh 2>&1 | artifact_out
    artifact_log "=========="
    oc exec $rpod -c logrotate -- /usr/bin/cat /opt/app-root/bin/logrotate_pod.sh 2>&1 | artifact_out
    artifact_log "=========="
    artifact_log "environment variables"
    oc exec $rpod -c logrotate -- env | grep LOGGING_FILE_ 2>&1 | artifact_out
    artifact_log "=========="
    oc exec $rpod -c logrotate -- /usr/bin/cat /tmp/.logrotate 2>&1 | artifact_out
    artifact_log "=========="
    artifact_log "logrotate config files"
    oc exec $rpod -c logrotate -- /usr/bin/cat /tmp/logrotate.conf 2>&1 | artifact_out
    artifact_log "=========="
    oc exec $rpod -c logrotate -- /usr/bin/cat /tmp/logrotate_pod.conf 2>&1 | artifact_out
    artifact_log "=========="
    artifact_log "rotated results"
    oc exec $rpod -c rsyslog -- ls -l /var/log/rsyslog/ 2>&1 | artifact_out
    artifact_log "=========="
    oc exec $rpod -c rsyslog -- ls -l /var/lib/rsyslog.pod/ 2>&1 | artifact_out
    artifact_log "=========="
    artifact_log "logrotate logs"
    oc exec $rpod -c logrotate -- /usr/bin/cat /var/log/rsyslog/logrotate.log 2>&1 | artifact_out
    artifact_log "=========="
    oc exec $rpod -c logrotate -- /usr/bin/cat /var/lib/rsyslog.pod/logrotate.log 2>&1 | artifact_out
    artifact_log "=========="
    os::cmd::expect_success "test $filecount -le $maxcount"
    os::cmd::expect_success "test $filesize -le $(( maxsize + 2048 ))"

    oc apply --force -f $savecm
else
    artifact_log ERROR rsyslog log is empty.
fi

# switch LOGGING_FILE_PATH to console
stop_rsyslog $rpod
oc set env $rsyslog_ds LOGGING_FILE_PATH=console
start_rsyslog
rpod=$( get_running_pod rsyslog )
oc logs $rpod -c rsyslog > $ARTIFACT_DIR/rsyslog.console.log 2>&1
os::cmd::expect_failure "grep 'oc exec <pod_name> -- logs' $ARTIFACT_DIR/rsyslog.console.log"

# switch back LOGGING_FILE_PATH SIZE and AGE to default
stop_rsyslog $rpod
oc set env $rsyslog_ds LOGGING_FILE_PATH- LOGGING_FILE_SIZE- LOGGING_FILE_AGE-
start_rsyslog
rpod=$( get_running_pod rsyslog )

artifact_log "************************"
artifact_log "Testing undefined fields"
artifact_log "************************"

artifact_log "0. Preparing test data"
cfgdir=$( mktemp -d )
oc extract cm/rsyslog --to=$cfgdir
cat > $cfgdir/66-debug.conf << EOF
set \$.ret = parse_json('{"undefined1":"undefined1","undefined11":1111,"undefined12":True,"empty1":"","undefined2":{"undefined2":"undefined2","":"","undefined22":2222,"undefined23":False},"undefined3":{"emptyvalue":""},"undefined4":"undefined4","undefined5":"undefined5","undefined.6":"undefined6"}', '\$!');
EOF
ls -l $cfgdir | artifact_out
stop_rsyslog $rpod
oc delete cm rsyslog
oc create cm rsyslog --from-file=$cfgdir
start_rsyslog
rpod=$( get_running_pod rsyslog )

oc exec $rpod -c rsyslog -- ls -l /etc/rsyslog.d/66-debug.conf | artifact_out
oc exec $rpod -c rsyslog -- cat /etc/rsyslog.d/66-debug.conf | artifact_out

# MERGE_JSON_LOG=true needs to be enabled in the following tests.
stop_rsyslog $rpod
oc set env $rsyslog_ds MERGE_JSON_LOG=true
start_rsyslog
rpod=$( get_running_pod rsyslog )

artifact_log "1. default values"
# skipped empty by mmnormalize/parse_json_skip_empty; mmexternal won't be executed.
wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
cat $proj > $ARTIFACT_DIR/undef1.proj.json 2>&1 || :
cat $ops > $ARTIFACT_DIR/undef1.ops.json 2>&1 || :
os::cmd::expect_success "cat $proj | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test1"
os::cmd::expect_success "cat $ops | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test1"

artifact_log "2. enable use_undefined - undefined fields are stored in 'undefined' field"
keep_fields="method,statusCode,type,@timestamp,req,res,CONTAINER_NAME,CONTAINER_ID_FULL"
stop_rsyslog $rpod
oc set env $rsyslog_ds UNDEFINED_DEBUG=true MERGE_JSON_LOG=true CDM_USE_UNDEFINED=true CDM_EXTRA_KEEP_FIELDS=$keep_fields 2>&1 | artifact_out
start_rsyslog
rpod=$( get_running_pod rsyslog )
os::cmd::try_until_success "oc exec $rpod -c rsyslog -- grep 'use_undefined:' /var/log/rsyslog/rsyslog.log"
os::cmd::expect_success_and_text "oc exec $rpod -c rsyslog -- grep 'use_undefined:' /var/log/rsyslog/rsyslog.log | tail -n 1 | awk '{print \$3}'" "true"
oc exec $rpod -c rsyslog -- cat /var/lib/rsyslog.pod/undefined.json | artifact_out

wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
cat $proj > $ARTIFACT_DIR/undef2.proj.json 2>&1 || :
cat $ops > $ARTIFACT_DIR/undef2.ops.json 2>&1 || :
os::cmd::expect_success "cat $proj | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test2"
os::cmd::expect_success "cat $ops | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test2"

artifact_log "3. user specifies extra fields to keep"
stop_rsyslog $rpod
oc set env $rsyslog_ds UNDEFINED_DEBUG=true MERGE_JSON_LOG=true CDM_USE_UNDEFINED=true CDM_EXTRA_KEEP_FIELDS=undefined4,undefined5,$keep_fields 2>&1 | artifact_out
start_rsyslog
rpod=$( get_running_pod rsyslog )
os::cmd::expect_success_and_text "oc exec $rpod -c rsyslog -- grep 'extra_keep_fields:' /var/log/rsyslog/rsyslog.log | tail -n 1 | awk '{print \$3}' | sed -e 's/.*\(undefined4\).*/\1/'" "undefined4"
oc exec $rpod -c rsyslog -- cat /var/lib/rsyslog.pod/undefined.json | artifact_out

wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
cat $proj > $ARTIFACT_DIR/undef3.proj.json 2>&1 || :
cat $ops > $ARTIFACT_DIR/undef3.ops.json 2>&1 || :
os::cmd::expect_success "cat $proj | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test3"
os::cmd::expect_success "cat $ops | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test3"

artifact_log "4. user specifies alternate undefined name to use"
stop_rsyslog $rpod
oc set env $rsyslog_ds UNDEFINED_DEBUG=true MERGE_JSON_LOG=true CDM_USE_UNDEFINED=true CDM_EXTRA_KEEP_FIELDS=undefined4,undefined5,$keep_fields CDM_UNDEFINED_NAME=myname 2>&1 | artifact_out
start_rsyslog
rpod=$( get_running_pod rsyslog )
os::cmd::try_until_success "oc exec $rpod -c rsyslog -- grep 'undefined_name:' /var/log/rsyslog/rsyslog.log | tail -n 1 | awk '{print \$3}' | grep myname"
oc exec $rpod -c rsyslog -- cat /var/lib/rsyslog.pod/undefined.json | artifact_out

wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
cat $proj > $ARTIFACT_DIR/undef4.proj.json 2>&1 || :
cat $ops > $ARTIFACT_DIR/undef4.ops.json 2>&1 || :
os::cmd::expect_success "cat $proj | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test4"
os::cmd::expect_success "cat $ops | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test4"

artifact_log "5. reserve specified empty field as empty"
stop_rsyslog
oc set env $rsyslog_ds UNDEFINED_DEBUG=true MERGE_JSON_LOG=true CDM_USE_UNDEFINED=true CDM_EXTRA_KEEP_FIELDS=undefined4,undefined5,empty1,undefined3,$keep_fields CDM_UNDEFINED_NAME=myname CDM_KEEP_EMPTY_FIELDS=undefined4,undefined5,empty1,undefined3 2>&1 | artifact_out
start_rsyslog
rpod=$( get_running_pod rsyslog )
os::cmd::try_until_success "oc exec $rpod -c rsyslog -- grep 'keep_empty_fields:' /var/log/rsyslog/rsyslog.log | tail -n 1 | awk '{print \$3}' | sed -e 's/.*\(empty1\).*/\1/' | grep empty1"
oc exec $rpod -c rsyslog -- cat /var/lib/rsyslog.pod/undefined.json | artifact_out

wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
cat $proj > $ARTIFACT_DIR/undef5.proj.json 2>&1 || :
cat $ops > $ARTIFACT_DIR/undef5.ops.json 2>&1 || :
os::cmd::expect_success "cat $proj | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test5 allow_empty"
os::cmd::expect_success "cat $ops | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test5 allow_empty"

artifact_log "6. replace dot with underscore"
stop_rsyslog $rpod
oc set env $rsyslog_ds UNDEFINED_DEBUG=true MERGE_JSON_LOG=true CDM_USE_UNDEFINED=true CDM_EXTRA_KEEP_FIELDS=undefined4,undefined5,empty1,undefined3,$keep_fields CDM_UNDEFINED_NAME=myname CDM_KEEP_EMPTY_FIELDS=undefined4,undefined5,empty1,undefined3 CDM_UNDEFINED_DOT_REPLACE_CHAR=_ 2>&1 | artifact_out
start_rsyslog
rpod=$( get_running_pod rsyslog )
oc exec $rpod -c rsyslog -- cat /var/lib/rsyslog.pod/undefined.json | artifact_out

wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
cat $proj > $ARTIFACT_DIR/undef6.proj.json 2>&1 || :
cat $ops > $ARTIFACT_DIR/undef6.ops.json 2>&1 || :
os::cmd::expect_success "cat $proj | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test6 allow_empty"
os::cmd::expect_success "cat $ops | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test6 allow_empty"

artifact_log "7. set CDM_UNDEFINED_MAX_NUM_FIELDS to 3"
stop_rsyslog $rpod
oc set env $rsyslog_ds UNDEFINED_DEBUG=true MERGE_JSON_LOG=true CDM_USE_UNDEFINED=true CDM_EXTRA_KEEP_FIELDS=undefined4,undefined5,empty1,undefined3,$keep_fields CDM_KEEP_EMPTY_FIELDS=undefined4,undefined5,empty1,undefined3 CDM_UNDEFINED_DOT_REPLACE_CHAR=_ CDM_UNDEFINED_MAX_NUM_FIELDS=3 CDM_UNDEFINED_NAME=undefString 2>&1 | artifact_out
start_rsyslog
rpod=$( get_running_pod rsyslog )
oc exec $rpod -c rsyslog -- cat /var/lib/rsyslog.pod/undefined.json | artifact_out

wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
cat $proj > $ARTIFACT_DIR/undef7.proj.json 2>&1 || :
cat $ops > $ARTIFACT_DIR/undef7.ops.json 2>&1 || :
os::cmd::expect_success "cat $proj | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test7 allow_empty"
os::cmd::expect_success "cat $ops | python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test7 allow_empty"

os::cmd::expect_success "oc exec $rpod -c rsyslog -- ls -l /var/log/rsyslog/rsyslog.log"
os::cmd::expect_failure "oc exec $rpod -c rsyslog -- grep 'panic: interface conversion' /var/log/rsyslog/rsyslog.log"

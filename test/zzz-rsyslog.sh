#!/bin/bash

# This is a test suite for testing basic log processing
# functionality and Kubernetes processing for rsyslog

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/zzz-rsyslog"

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
        oc get clusterlogging instance -o yaml > $ARTIFACT_DIR/clinstance.yaml 2>&1
        oc describe deploy cluster-logging-operator > $ARTIFACT_DIR/deploy.clo.yaml 2>&1
        oc describe ds rsyslog > $ARTIFACT_DIR/ds.rsyslog.yaml 2>&1
        oc patch clusterlogging instance --type=json \
            --patch '[{"op":"replace","path":"/spec/collection/logs/type","value":"fluentd"}]' 2>&1 | artifact_out
        enable_cluster_logging_operator
        oc label node --all logging-infra-rsyslog-
        os::cmd::try_until_failure "oc get pods $rpod > /dev/null 2>&1"
        start_fluentd true 2>&1 | artifact_out
        disable_cluster_logging_operator
        sleep 10
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
    os::cmd::try_until_success "oc get pods 2> /dev/null | grep -q 'rsyslog.*Running'"
    rpod=$( get_running_pod rsyslog )
    disable_cluster_logging_operator
    sleep 10
    os::cmd::try_until_success "oc get cm rsyslog 2> /dev/null"
    # enable annotation_match
    oc get cm rsyslog -o yaml | \
      sed -e 's/action(type="mmkubernetes"/action(type="mmkubernetes" annotation_match=["."]/' | \
      oc replace --force -f - 2>&1 | artifact_out
    oc delete --force pod $rpod
    os::cmd::try_until_failure "oc get pods $rpod > /dev/null 2>&1"
    os::cmd::try_until_success "oc get pods 2> /dev/null | grep -q 'rsyslog.*Running'"
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

# see if the prometheus exporter is working
rpod="$( get_running_pod rsyslog )"
rpod_ip="$( oc get pod ${rpod} -o jsonpath='{.status.podIP}' )"

os::cmd::try_until_success "curl -s -k https://${rpod_ip}:24231/metrics"
curl -s -k https://${rpod_ip}:24231/metrics >> $ARTIFACT_DIR/${rpod}-metrics-scrape 2>&1 || :

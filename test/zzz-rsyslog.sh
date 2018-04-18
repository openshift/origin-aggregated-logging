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

cleanup() {
    local return_code="$?"
    set +e
    if [ -n "${tmpinv}" -a -f "${tmpinv}" ] ; then
        rm -f $tmpinv
    fi
    sudo journalctl -u rsyslog --since="-1hour" > $ARTIFACT_DIR/rsyslog-rsyslog.log 2>&1
    if [ -n "${rsyslog_save}" -a -d "${rsyslog_save}" ] ; then
        sudo rm -rf /etc/rsyslog.d/*
        sudo cp -p ${rsyslog_save}/* /etc/rsyslog.d
        rm -rf ${rsyslog_save}
        sudo systemctl restart rsyslog
    fi
    # cleanup fluentd pos file and restart
    flush_fluentd_pos_files
    oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

# turn off fluentd
oc label node --all logging-infra-fluentd- 2>&1 | artifact_out || :
os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $((second * 120))

if [ $es_pod = $es_ops_pod ] ; then
    use_es_ops=False
else
    use_es_ops=True
fi
rsyslog_save=$( mktemp -d )
sudo cp -p /etc/rsyslog.d/* $rsyslog_save
pushd $OS_O_A_L_DIR/hack/testing/rsyslog > /dev/null
tmpinv=$( mktemp )
cat > $tmpinv <<EOF
localhost ansible_ssh_user=${RSYSLOG_ANSIBLE_SSH_USER:-ec2-user} openshift_logging_use_ops=$use_es_ops openshift_logging_namespace=${LOGGING_NS:-logging}
EOF
os::cmd::expect_success "ansible-playbook -vvv --become --become-user root --connection local \
    -e use_mmk8s=True -i $tmpinv playbook.yaml > $ARTIFACT_DIR/zzz-rsyslog-ansible.log 2>&1"
rm -f $tmpinv
popd > /dev/null

get_logmessage() {
    logmessage="$1"
    cp $2 $ARTIFACT_DIR/zzz-rsyslog-record.json
}
get_logmessage2() {
    logmessage2="$1"
    cp $2 $ARTIFACT_DIR/zzz-rsyslog-record-ops.json
}
sudo systemctl stop rsyslog
# make test run faster by resetting journal cursor to "now"
sudo journalctl -n 1 --show-cursor | awk '/^-- cursor/ {printf("%s",$3)}' | sudo tee /var/lib/rsyslog/imjournal.state > /dev/null
sudo systemctl start rsyslog
sleep 10
wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
proj=$ARTIFACT_DIR/zzz-rsyslog-record.json
ops=$ARTIFACT_DIR/zzz-rsyslog-record-ops.json

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
    os::cmd::expect_success_and_text "cat $proj | jq .hits.hits[0]._source.metadata.namespace_labels" "^null\$"
fi

if [ -n "$( oc get project $actual_ns_name -o jsonpath='{.metadata.annotations}')" ] ; then
    oc get project $actual_ns_name -o json | jq -S .metadata.annotations | \
        jq 'with_entries(.key |= gsub("[.]";"_"))' > $ARTIFACT_DIR/zzz-rsyslog-expected-nsannotations.json
    cat $proj | jq -S '.hits.hits[0]._source.kubernetes.namespace_annotations' > $ARTIFACT_DIR/zzz-rsyslog-actual-nsannotations.json
    os::cmd::expect_success "diff $ARTIFACT_DIR/zzz-rsyslog-expected-nsannotations.json $ARTIFACT_DIR/zzz-rsyslog-actual-nsannotations.json"
else
    os::cmd::expect_success_and_text "cat $proj | jq .hits.hits[0]._source.metadata.namespace_annotations" "^null\$"
fi

# see if ops fields are present
os::cmd::expect_success_and_not_text "cat $ops | jq -r .hits.hits[0]._source.systemd.t.TRANSPORT" "^null$"
os::cmd::expect_success_and_not_text "cat $ops | jq -r .hits.hits[0]._source.systemd.t.SELINUX_CONTEXT" "^null$"
os::cmd::expect_success_and_not_text "cat $ops | jq -r .hits.hits[0]._source.systemd.u.SYSLOG_FACILITY" "^null$"
os::cmd::expect_success_and_not_text "cat $ops | jq -r .hits.hits[0]._source.systemd.u.SYSLOG_PID" "^null$"
os::cmd::expect_success_and_text "cat $ops | jq -r .hits.hits[0]._source.message" "^${logmessage2}\$"
os::cmd::expect_success_and_not_text "cat $ops | jq -r .hits.hits[0]._source.level" "^null$"
os::cmd::expect_success_and_not_text "cat $ops | jq -r .hits.hits[0]._source.hostname" "^null$"
ts=$( cat $ops | jq -r '.hits.hits[0]._source."@timestamp"' )
os::cmd::expect_success "test ${ts} != null"

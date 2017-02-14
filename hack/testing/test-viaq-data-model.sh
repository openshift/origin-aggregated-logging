#!/bin/bash

if [[ $VERBOSE ]]; then
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

if [[ $# -ne 1 || "$1" = "false" ]]; then
  # assuming not using OPS cluster
  CLUSTER="false"
  ops=
else
  CLUSTER="$1"
  ops="-ops"
fi

# not used for now, but in case
INDEX_PREFIX=
PROJ_PREFIX=project.

ARTIFACT_DIR=${ARTIFACT_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging}
if [ ! -d $ARTIFACT_DIR ] ; then
    mkdir -p $ARTIFACT_DIR
fi

get_test_user_token

get_logmessage() {
    logmessage="$1"
}
get_logmessage2() {
    logmessage2="$1"
}

write_and_verify_logs() {
    expected=1
    rc=0
    if ! wait_for_fluentd_to_catch_up get_logmessage get_logmessage2 ; then
        rc=1
    fi

    kpod=`get_running_pod kibana`
    if [ $rc = "0" ] ; then
        # get the record - verify result matches expected data
        if curl_es_from_kibana $kpod logging-es ${PROJ_PREFIX}logging _search message $logmessage | \
                python test-viaq-data-model.py $1 ${2:-} ; then
            : # good
        else
            echo Error: result data does not match expected
            rc=1
        fi
    fi

    if [ $rc = "0" ] ; then
        # get the record - verify result matches expected data
        if curl_es_from_kibana $kpod logging-es${ops} ${INDEX_PREFIX}.operations _search message $logmessage2 | \
                python test-viaq-data-model.py $1 ${2:-} ; then
            : # good
        else
            echo Error: result data does not match expected
            rc=1
        fi
    fi

    if [ $rc != "0" ] ; then
        echo test-viaq-data-model.sh: returning $rc ...
    fi

    return $rc
}

remove_test_volume() {
    oc get template logging-fluentd-template -o json | \
        python -c 'import json, sys; obj = json.loads(sys.stdin.read()); vm = obj["objects"][0]["spec"]["template"]["spec"]["containers"][0]["volumeMounts"]; obj["objects"][0]["spec"]["template"]["spec"]["containers"][0]["volumeMounts"] = [xx for xx in vm if xx["name"] != "cdmtest"]; vs = obj["objects"][0]["spec"]["template"]["spec"]["volumes"]; obj["objects"][0]["spec"]["template"]["spec"]["volumes"] = [xx for xx in vs if xx["name"] != "cdmtest"]; print json.dumps(obj, indent=2)' | \
        oc replace -f -
}

# takes json input, removes the "cdmtest" volume and volumeMount, returns
# json output
# oc get ... -o json | add_test_volume | oc replace -f -
# $1 is the local file to use for the volume hostPath
add_test_volume() {
    oc get template logging-fluentd-template -o json | \
        python -c 'import json, sys; obj = json.loads(sys.stdin.read()); obj["objects"][0]["spec"]["template"]["spec"]["containers"][0]["volumeMounts"].append({"name": "cdmtest", "mountPath": "/etc/fluent/configs.d/openshift/filter-pre-cdm-test.conf", "readOnly": True}); obj["objects"][0]["spec"]["template"]["spec"]["volumes"].append({"name": "cdmtest", "hostPath": {"path": "'$1'"}}); print json.dumps(obj, indent=2)' | \
        oc replace -f -
}

remove_cdm_env() {
    oc get template logging-fluentd-template -o yaml | \
        sed '/- name: CDM_/,/value:/d' | \
        oc replace -f -
}

add_cdm_env_var_val() {
    junk=`mktemp`
    cat > $junk <<EOF
          - name: "$1"
            value: $2
EOF
    oc get template logging-fluentd-template -o yaml | \
        sed "/env:/r $junk" | \
        oc replace -f -
    rm -f $junk
}

del_cdm_env_var() {
    oc get template logging-fluentd-template -o yaml | \
        sed "/- name: ${1}$/,/value:/d" | \
        oc replace -f -
}

restart_fluentd() {
    # delete daemonset which also stops fluentd
    oc delete daemonset logging-fluentd
    # wait for fluentd to stop
    wait_for_pod_ACTION stop $fpod
    # create the daemonset which will also start fluentd
    oc process logging-fluentd-template | oc create -f -
    # wait for fluentd to start
    wait_for_pod_ACTION start fluentd
}

TEST_DIVIDER="------------------------------------------"

# configure fluentd with a test filter that adds undefined and empty fields/hashes
# verify that undefined fields are stored in a top level field with a hash value
# the hash holds all of the other top level fields that are undefined
# also verify that the output contains no empty fields, including empty hashes

fpod=`get_running_pod fluentd`

# first, make sure the cdm test filter is not being used
remove_test_volume
# add the test volume
cfg=`mktemp`
cat > $cfg <<EOF
<filter **>
  @type record_transformer
  enable_ruby
  auto_typecast
  <record>
    undefined1 undefined1
    undefined11 \${1111}
    undefined12 \${true}
    empty1 ""
    undefined2 {"undefined2":"undefined2","":"","undefined22":2222,"undefined23":false}
    undefined3 {"":""}
    undefined4 undefined4
    undefined5 undefined5
  </record>
</filter>
EOF
add_test_volume $cfg

cleanup() {
    remove_test_volume
    remove_cdm_env
    rm -f $cfg
    restart_fluentd
}
trap "cleanup" INT TERM EXIT

restart_fluentd
fpod=`get_running_pod fluentd`

# these fields are present because it is a kibana log message - we
# want to ignore them for the purposes of our tests
keep_fields="method,statusCode,type,@timestamp"

# TEST 1
# default - undefined fields are passed through untouched

# run test to make sure fluentd is working normally
write_and_verify_logs test1 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

# TEST 2
# cdm - undefined fields are stored in 'undefined' field
add_cdm_env_var_val CDM_USE_UNDEFINED '"true"'
add_cdm_env_var_val CDM_EXTRA_KEEP_FIELDS $keep_fields
restart_fluentd
fpod=`get_running_pod fluentd`

# run test to make sure fluentd is working normally
write_and_verify_logs test2 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

# TEST 3
# user specifies extra fields to keep
del_cdm_env_var CDM_EXTRA_KEEP_FIELDS
add_cdm_env_var_val CDM_EXTRA_KEEP_FIELDS undefined4,undefined5,$keep_fields
restart_fluentd
fpod=`get_running_pod fluentd`

# run test to make sure fluentd is working normally
write_and_verify_logs test3 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

# TEST 4
# user specifies alternate undefined name to use
add_cdm_env_var_val CDM_UNDEFINED_NAME myname
restart_fluentd
fpod=`get_running_pod fluentd`

# run test to make sure fluentd is working normally
write_and_verify_logs test4 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

# TEST 5
# preserve specified empty field as empty
del_cdm_env_var CDM_EXTRA_KEEP_FIELDS
add_cdm_env_var_val CDM_EXTRA_KEEP_FIELDS undefined4,undefined5,empty1,undefined3,$keep_fields
add_cdm_env_var_val CDM_KEEP_EMPTY_FIELDS undefined4,undefined5,empty1,undefined3
restart_fluentd
fpod=`get_running_pod fluentd`

# run test to make sure fluentd is working normally
write_and_verify_logs test5 allow_empty || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

#!/bin/bash

# test that logging will parse the message field containing
# embedded JSON into its component fields, and use the
# original message field in the embedded JSON

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

FLUENTD_WAIT_TIME=$(( 2 * minute ))

os::test::junit::declare_suite_start "test/viaq-data-model"

if [ -n "${DEBUG:-}" ] ; then
    set -x
fi

cleanup() {
    local return_code="$?"
    set +e
    if [ $return_code = 0 ] ; then
        mycmd=os::log::info
    else
        mycmd=os::log::error
    fi
    $mycmd viaq-data-model test finished at $( date )
    # dump the pod before we restart it
    if [ -n "${fpod:-}" ] ; then
        oc logs $fpod > $ARTIFACT_DIR/$fpod.log 2>&1
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd- 2>&1 || : )"
    os::cmd::try_until_failure "oc get pod $fpod" $FLUENTD_WAIT_TIME
    if [ -n "${savecm:-}" -a -f "${savecm:-}" ] ; then
        os::log::debug "$( oc replace --force -f $savecm )"
    fi
    if [ -n "${saveds:-}" -a -f "${saveds:-}" ] ; then
        os::log::debug "$( oc replace --force -f $saveds )"
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd=true 2>&1 || : )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

# Make sure all the pods are running at the beginning of the test suite.
os::cmd::try_until_text "oc get pods -l component=es" "^logging-es.* Running "
os::cmd::try_until_text "oc get pods -l component=kibana" "^logging-kibana-.* Running "
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
if [ "${USE_MUX:-}" = "true" ]; then
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running "
fi
os::log::debug "$( oc get pods )"

# save current fluentd daemonset
saveds=$( mktemp )
oc get daemonset logging-fluentd -o yaml > $saveds

# save current fluentd configmap
savecm=$( mktemp )
oc get configmap logging-fluentd -o yaml > $savecm

os::log::info Starting viaq-data-model test at $( date )

es_pod=$( get_es_pod es )
es_ops_pod=$( get_es_pod es-ops )
es_ops_pod=${es_ops_pod:-$es_pod}

fpod=$( get_running_pod fluentd )
os::log::debug "$( oc label node --all logging-infra-fluentd- 2>&1 || : )"
os::cmd::try_until_failure "oc get pod $fpod" $FLUENTD_WAIT_TIME

# doesn't currently work with MUX_CLIENT_MODE=minimal - force to maximal
if oc set env daemonset/logging-fluentd --list | grep -q ^MUX_CLIENT_MODE=minimal ; then
    os::log::info MUX_CLIENT_MODE=minimal not supported - using MUX_CLIENT_MODE=maximal for test
    oc set env ds/logging-fluentd MUX_CLIENT_MODE=maximal
fi

# make sure we are not using the test volume
os::log::debug "$( oc set volumes daemonset/logging-fluentd --remove --name=viaq-test 2>&1 || : )"
# create test filter file
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

# add our test filter to the fluentd pipeline via a volume mount
os::log::debug "$( oc set volumes daemonset/logging-fluentd --add --name=viaq-test \
                   -t hostPath -m /etc/fluent/configs.d/openshift/filter-pre-cdm-test.conf \
                   --path $cfg )"

os::log::debug "$( oc label node --all logging-infra-fluentd=true 2>&1 || : )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )

get_logmessage() {
    logmessage="$1"
}
get_logmessage2() {
    logmessage2="$1"
}

# TEST 1
# default - undefined fields are passed through untouched
wait_for_fluentd_ready
wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
fullmsg="GET /${logmessage} 404 "
qs='{"query":{"match_phrase":{"message":"'"${fullmsg}"'"}}}'
os::cmd::expect_success "curl_es $es_pod /project.logging.*/_search -X POST -d '$qs' | \
                         python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test1"
qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${logmessage2}"'"}}}'
os::cmd::expect_success "curl_es $es_ops_pod /.operations.*/_search -X POST -d '$qs' | \
                         python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test1"

# these fields are present because it is a kibana log message - we
# want to ignore them for the purposes of our tests
# keep CONTAINER_NAME,CONTAINER_ID_FULL because when using mux we want to pass
# these from fluentd to mux
keep_fields="method,statusCode,type,@timestamp,req,res,CONTAINER_NAME,CONTAINER_ID_FULL"

# TEST 2
# cdm - undefined fields are stored in 'undefined' field
os::log::debug "$( oc set env daemonset/logging-fluentd CDM_USE_UNDEFINED=true CDM_EXTRA_KEEP_FIELDS=$keep_fields )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
wait_for_fluentd_ready
wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
fullmsg="GET /${logmessage} 404 "
qs='{"query":{"match_phrase":{"message":"'"${fullmsg}"'"}}}'
os::cmd::expect_success "curl_es $es_pod /project.logging.*/_search -X POST -d '$qs' | \
                         python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test2"
qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${logmessage2}"'"}}}'
os::cmd::expect_success "curl_es $es_ops_pod /.operations.*/_search -X POST -d '$qs' | \
                         python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test2"

# TEST 3
# user specifies extra fields to keep
os::log::debug "$( oc set env daemonset/logging-fluentd CDM_EXTRA_KEEP_FIELDS=undefined4,undefined5,$keep_fields )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
wait_for_fluentd_ready
wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
fullmsg="GET /${logmessage} 404 "
qs='{"query":{"match_phrase":{"message":"'"${fullmsg}"'"}}}'
os::cmd::expect_success "curl_es $es_pod /project.logging.*/_search -X POST -d '$qs' | \
                         python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test3"

qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${logmessage2}"'"}}}'
os::cmd::expect_success "curl_es $es_ops_pod /.operations.*/_search -X POST -d '$qs' | \
                         python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test3"

# TEST 4
# user specifies alternate undefined name to use
os::log::debug "$( oc set env daemonset/logging-fluentd CDM_UNDEFINED_NAME=myname )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
wait_for_fluentd_ready
wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
fullmsg="GET /${logmessage} 404 "
qs='{"query":{"match_phrase":{"message":"'"${fullmsg}"'"}}}'
os::cmd::expect_success "curl_es $es_pod /project.logging.*/_search -X POST -d '$qs' | \
                         python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test4"

qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${logmessage2}"'"}}}'
os::cmd::expect_success "curl_es $es_ops_pod /.operations.*/_search -X POST -d '$qs' | \
                         python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test4"

# TEST 5
# preserve specified empty field as empty
os::log::debug "$( oc set env daemonset/logging-fluentd CDM_EXTRA_KEEP_FIELDS=undefined4,undefined5,empty1,undefined3,$keep_fields CDM_KEEP_EMPTY_FIELDS=undefined4,undefined5,empty1,undefined3 )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
# if using MUX_CLIENT_MODE=maximal, also have to tell mux to keep the empty fields
if oc set env daemonset/logging-fluentd --list | grep -q ^MUX_CLIENT_MODE=maximal ; then
    muxpod=$( get_running_pod mux )
    oc set env dc/logging-mux CDM_KEEP_EMPTY_FIELDS=undefined4,undefined5,empty1,undefined3
    os::cmd::try_until_failure "oc get pod $muxpod"
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running "
fi
fpod=$( get_running_pod fluentd )
wait_for_fluentd_ready
wait_for_fluentd_to_catch_up get_logmessage get_logmessage2
fullmsg="GET /${logmessage} 404 "
qs='{"query":{"match_phrase":{"message":"'"${fullmsg}"'"}}}'
os::cmd::expect_success "curl_es $es_pod /project.logging.*/_search -X POST -d '$qs' | \
                         python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test5 allow_empty"

qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${logmessage2}"'"}}}'
os::cmd::expect_success "curl_es $es_ops_pod /.operations.*/_search -X POST -d '$qs' | \
                         python $OS_O_A_L_DIR/hack/testing/test-viaq-data-model.py test5 allow_empty"

if oc set env daemonset/logging-fluentd --list | grep -q ^MUX_CLIENT_MODE=maximal ; then
    muxpod=$( get_running_pod mux )
    oc set env dc/logging-mux CDM_KEEP_EMPTY_FIELDS-
    os::cmd::try_until_failure "oc get pod $muxpod"
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running "
fi

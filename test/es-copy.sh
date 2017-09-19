#!/bin/bash

# This is a test suite for the ES_COPY settings

# doesn't currently work with mux
if [ -n "${MUX_CLIENT_MODE:-}" ] ; then
    echo $0 does not currently work with MUX_CLIENT_MODE - skipping
    exit 0
fi

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/es-copy"

if [ -n "${DEBUG:-}" ] ; then
    set -x
fi

# save current fluentd daemonset
saveds=$( mktemp )
oc get daemonset logging-fluentd -o yaml > $saveds

cmap=$( mktemp )
oc get configmap/logging-fluentd -o yaml > $cmap

cleanup() {
    local return_code="$?"
    set +e
    if [ $return_code = 0 ] ; then
        mycmd=os::log::info
    else
        mycmd=os::log::error
    fi

    $mycmd es-copy test finished at $( date )
    # dump the pod before we restart it
    if [ -n "${fpod:-}" ] ; then
        oc logs $fpod > $ARTIFACT_DIR/$fpod.log 2>&1
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd- 2>&1 || : )"
    os::cmd::try_until_failure "oc get pod $fpod"
    if [ -n "${cmap:-}" -a -f "${cmap:-}" ] ; then
        os::log::debug "$( oc replace --force -f $cmap 2>&1 || : )"
    fi
    if [ -n "${saveds:-}" -a -f "${saveds:-}" ] ; then
        os::log::debug "$( oc replace --force -f $saveds )"
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd=true || : )"
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

check_copy_conf () {
  local expect=$1
  local copy_conf_file=$2
  local fpod=$( get_running_pod fluentd )
  local existcopy=""
  local lsout=$( oc exec $fpod -- ls -l /etc/fluent/configs.d/dynamic/$copy_conf_file 2>&1 || : )
  if expr "$lsout" : ".* No such file" > /dev/null ; then
    existcopy="false"
    verb="does not exist"
  else
    fsize=$( echo $lsout | awk '{print $5}' )
    if [ $fsize -le 1 ]; then
      existcopy="false"
      verb="does not exist"
    else
      existcopy="true"
      verb="exists"
    fi
  fi
  if [ "$expect" = "$existcopy" ]; then
     result="good"
     mycmd=os::log::debug
  else
     result="failed"
     mycmd=os::log::error
  fi
  $mycmd "$result - $copy_conf_file $verb."
}

os::log::info Starting es-copy test at $( date )

# first, make sure copy is off
os::log::debug "$( oc set env daemonset/logging-fluentd ES_COPY=false )"
# if it was true, changing the value will trigger a restart
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
wait_for_fluentd_ready
os::cmd::expect_success wait_for_fluentd_to_catch_up

envvars=""
turnoffcopysettings=""
# for every ES_ or OPS_ setting, create a copy called ES_COPY_ or OPS_COPY_
for k_eq_val in $( oc set env daemonset/logging-fluentd --list | grep -v \^# ) ; do
    case "$k_eq_val" in
        ES_COPY_*) continue ;;
        OPS_COPY_*) continue ;;
        ES_*) new=$( echo $k_eq_val | sed s/ES_/ES_COPY_/ ); envvars="$envvars $new" ;;
        OPS_*) new=$( echo $k_eq_val | sed s/OPS_/OPS_COPY_/ ); envvars="$envvars $new" ;;
        *) continue ;;
    esac
    val=$( echo $new | sed 's/=.*$//' )
    turnoffcopysettings="$turnoffcopysettings ${val}-"
done

envvars="$envvars ES_COPY=true ES_COPY_SCHEME=https OPS_COPY_SCHEME=https"
turnoffcopysettings="$turnoffcopysettings ES_COPY- ES_COPY_SCHEME- OPS_COPY_SCHEME-"
if [ -n "${DEBUG:-}" ] ; then
    envvars="$envvars VERBOSE=true"
    turnoffcopysettings="$turnoffcopysettings VERBOSE-"
fi
# turn on all of the COPY settings
os::log::debug "$( oc set env daemonset/logging-fluentd $envvars )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )

wait_for_fluentd_ready
check_copy_conf false "es-copy-config.conf"
check_copy_conf false "es-ops-copy-config.conf"
os::cmd::expect_success "wait_for_fluentd_to_catch_up '' '' 1"
os::cmd::expect_success_and_text "oc logs $fpod 2>&1" "Disabling the copy"

newenvvars=""
for k_eq_val in $envvars ; do
    case "$k_eq_val" in
        *_COPY_HOST*) new=$( echo $k_eq_val | sed 's/\(=.*$\)/\1-copy/' ); newenvvars="$newenvvars $new" ;;
        VERBOSE*) newenvvars="$newenvvars $k_eq_val" ;;
        *) continue ;;
    esac
done
newenvvars="$newenvvars ES_COPY=true ES_COPY_SCHEME=https OPS_COPY_SCHEME=https SET_ES_COPY_HOST_ALIAS=true"

modcmap=$( mktemp )
sed -n '{
s/^ *@include configs.d\/openshift\/output-operations.conf/    <match journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops>\
     @type copy\
     @include configs.d\/dynamic\/output-es-ops-config.conf\
     @include configs.d\/user\/output-ops-extra-*.conf\
     <store>\
        @type elasticsearch_dynamic\
        host \"#{ENV['"'OPS_COPY_HOST'"']}\"\
        port \"#{ENV['"'OPS_COPY_PORT'"']}\"\
        scheme \"#{ENV['"'OPS_COPY_SCHEME'"']}\"\
        index_name .operations.${record['"'@timestamp'"'].nil? ? Time.at(time).getutc.strftime(@logstash_dateformat) : Time.parse(record['"'@timestamp'"']).getutc.strftime(@logstash_dateformat)}\
        user \"#{ENV['"'OPS_COPY_USERNAME'"']}\"\
        password \"#{ENV['"'OPS_COPY_PASSWORD'"']}\"\
        client_key \"#{ENV['"'OPS_COPY_CLIENT_KEY'"']}\"\
        client_cert \"#{ENV['"'OPS_COPY_CLIENT_CERT'"']}\"\
        ca_file \"#{ENV['"'OPS_COPY_CA'"']}\"\
        type_name com.redhat.viaq.common\
        reload_connections false\
        reload_on_failure false\
        flush_interval 5s\
        max_retry_wait 300\
        disable_retry_limit true\
        buffer_type file\
        buffer_path '"'\/var\/lib\/fluentd\/buffer-es-ops-copy-config'"'\
        buffer_queue_limit \"#{ENV['"'BUFFER_QUEUE_LIMIT'"'] || '"'1024'"' }\"\
        buffer_chunk_limit \"#{ENV['"'BUFFER_SIZE_LIMIT'"'] || '"'1m'"' }\"\
        buffer_queue_full_action \"#{ENV['"'BUFFER_QUEUE_FULL_ACTION'"'] || '"'exception'"'}\"\
        ssl_verify false\
     <\/store>\
     @include configs.d\/user\/secure-forward.conf\
    <\/match>/
s/^ *@include configs.d\/openshift\/output-applications.conf/    <match **>\
     @type copy\
     @include configs.d\/openshift\/output-es-config.conf\
     @include configs.d\/user\/output-extra-*.conf\
     <store>\
        @type elasticsearch_dynamic\
        host \"#{ENV['"'ES_COPY_HOST'"']}\"\
        port \"#{ENV['"'ES_COPY_PORT'"']}\"\
        scheme \"#{ENV['"'ES_COPY_SCHEME'"']}\"\
        index_name project.${record['"'kubernetes'"']['"'namespace_name'"']}.${record['"'kubernetes'"']['"'namespace_id'"']}.${Time.parse(record['"'@timestamp'"']).getutc.strftime(@logstash_dateformat)}\
        user \"#{ENV['"'ES_COPY_USERNAME'"']}\"\
        password \"#{ENV['"'ES_COPY_PASSWORD'"']}\"\
        client_key \"#{ENV['"'ES_COPY_CLIENT_KEY'"']}\"\
        client_cert \"#{ENV['"'ES_COPY_CLIENT_CERT'"']}\"\
        ca_file \"#{ENV['"'ES_COPY_CA'"']}\"\
        type_name com.redhat.viaq.common\
        reload_connections false\
        reload_on_failure false\
        flush_interval 5s\
        max_retry_wait 300\
        disable_retry_limit true\
        buffer_type file\
        buffer_path '"'\/var\/lib\/fluentd\/buffer-es-copy-config'"'\
        buffer_queue_limit \"#{ENV['"'BUFFER_QUEUE_LIMIT'"'] || '"'1024'"' }\"\
        buffer_chunk_limit \"#{ENV['"'BUFFER_SIZE_LIMIT'"'] || '"'1m'"' }\"\
        buffer_queue_full_action \"#{ENV['"'BUFFER_QUEUE_FULL_ACTION'"'] || '"'exception'"'}\"\
        ssl_verify false\
     <\/store>\
     @include configs.d\/user\/secure-forward.conf\
    <\/match>/
p
}' $cmap > $modcmap
os::log::debug "$( oc replace --force -f $modcmap )"

# turn on all of the COPY settings
os::log::debug "$( oc set env daemonset/logging-fluentd $newenvvars )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )

wait_for_fluentd_ready
check_copy_conf true "es-copy-config.conf"
check_copy_conf true "es-ops-copy-config.conf"
os::cmd::expect_success "wait_for_fluentd_to_catch_up '' '' 2"

# turn off the COPY settings
os::log::debug "$( oc set env daemonset/logging-fluentd $turnoffcopysettings )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )

wait_for_fluentd_ready
os::cmd::expect_success wait_for_fluentd_to_catch_up

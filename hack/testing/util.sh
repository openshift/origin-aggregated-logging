#!/bin/bash

if ! type -t os::log::info > /dev/null ; then
    source "${OS_O_A_L_DIR:-..}/hack/lib/init.sh"
fi

function get_es_dcs() {
    oc get dc --selector logging-infra=elasticsearch -o name
}

function get_curator_dcs() {
    oc get dc --selector logging-infra=curator -o name
}

function get_es_pod() {
    # $1 - cluster name postfix
    if [ -z $(oc get dc -l cluster-name=logging-${1},es-node-role=clientdata --no-headers | awk '{print $1}') ] ; then
      oc get pods -l component=${1} --no-headers | awk '$3 == "Running" {print $1}'
    else
      oc get pods -l cluster-name=logging-${1},es-node-role=clientdata --no-headers | awk '$3 == "Running" {print $1}'
    fi
}

function get_running_pod() {
    # $1 is component for selector
    oc get pods -l component=$1 --no-headers | awk '$3 == "Running" {print $1}'
}

# set the test_token, test_name, and test_ip for token auth
function get_test_user_token() {
    local current_project; current_project="$( oc project -q )"
    oc login --username=${1:-${LOG_ADMIN_USER:-admin}} --password=${2:-${LOG_ADMIN_PW:-admin}} > /dev/null
    test_token="$(oc whoami -t)"
    test_name="$(oc whoami)"
    test_ip="127.0.0.1"
    oc login --username=system:admin > /dev/null
    oc project "${current_project}" > /dev/null
}

# $1 - kibana pod name
# $2 - es hostname (e.g. logging-es or logging-es-ops)
# $3 - project name (e.g. logging, test, .operations, etc.)
# $4 - _count or _search
# $5 - field to search
# $6 - search string
# stdout is the JSON output from Elasticsearch
# stderr is curl errors
curl_es_from_kibana() {
    oc exec $1 -c kibana -- curl --connect-timeout 1 -s -k \
       --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
       -H "X-Proxy-Remote-User: $test_name" -H "Authorization: Bearer $test_token" -H "X-Forwarded-For: 127.0.0.1" \
       "https://${2}:9200/${3}*/${4}\?q=${5}:${6}"
}

# $1 - es pod name
# $2 - es endpoint
# rest - any args to pass to curl
function curl_es() {
    local pod="$1"
    local endpoint="$2"
    shift; shift
    local args=( "${@:-}" )

    local secret_dir="/etc/elasticsearch/secret/"
    oc exec -c elasticsearch "${pod}" -- curl --silent --insecure "${args[@]}" \
                             --key "${secret_dir}admin-key"   \
                             --cert "${secret_dir}admin-cert" \
                             "https://localhost:9200${endpoint}"
}

# $1 - es pod name
# $2 - es endpoint
# rest - any args to pass to curl
function curl_es_input() {
    local pod="$1"
    local endpoint="$2"
    shift; shift
    local args=( "${@:-}" )

    local secret_dir="/etc/elasticsearch/secret/"
    oc exec -c elasticsearch -i "${pod}" -- curl --silent --insecure "${args[@]}" \
                                --key "${secret_dir}admin-key"   \
                                --cert "${secret_dir}admin-cert" \
                                "https://localhost:9200${endpoint}"
}

function curl_es_with_token() {
    local pod="$1"
    local endpoint="$2"
    local test_name="$3"
    local test_token="$4"
    shift; shift; shift; shift
    local args=( "${@:-}" )
    oc exec -c elasticsearch "${pod}" -- curl --silent --insecure "${args[@]}" \
                             -H "X-Proxy-Remote-User: $test_name" \
                             -H "Authorization: Bearer $test_token" \
                             -H "X-Forwarded-For: 127.0.0.1" \
                             "https://localhost:9200${endpoint}"
}

function curl_es_with_token_and_input() {
    local pod="$1"
    local endpoint="$2"
    local test_name="$3"
    local test_token="$4"
    shift; shift; shift; shift
    local args=( "${@:-}" )
    oc exec -c elasticsearch -i "${pod}" -- curl --silent --insecure "${args[@]}" \
                                -H "X-Proxy-Remote-User: $test_name" \
                                -H "Authorization: Bearer $test_token" \
                                -H "X-Forwarded-For: 127.0.0.1" \
                                "https://localhost:9200${endpoint}"
}

# $1 - es pod name
# $2 - index name (e.g. project.logging, project.test, .operations, etc.)
# $3 - _count or _search
# $4 - field to search
# $5 - search string
# stdout is the JSON output from Elasticsearch
# stderr is curl errors
function query_es_from_es() {
    curl_es "$1" "/${2}*/${3}?q=${4}:${5}" --connect-timeout 1
}

# $1 is es pod
# $2 is timeout
function wait_for_es_ready() {
    # test for ES to be up first and that our SG index has been created
    echo "Checking if Elasticsearch $1 is ready"
    secret_dir=/etc/elasticsearch/secret
    local ii=$2
    local path=${3:-.searchguard.$1}
    while ! response_code=$(oc exec -c elasticsearch $1 -- curl -s \
        --request HEAD --head --output /dev/null \
        --cacert $secret_dir/admin-ca \
        --cert $secret_dir/admin-cert \
        --key  $secret_dir/admin-key \
        --connect-timeout 1 \
        -w '%{response_code}' \
        "https://localhost:9200/$path") || test "${response_code:-}" != 200
    do
        sleep 1
        ii=`expr $ii - 1` || :
        if [ $ii -eq 0 ] ; then
            return 1
        fi
    done
    return 0
}

function get_count_from_json() {
    python -c 'import json, sys; print json.loads(sys.stdin.read()).get("count", 0)'
}

# https://github.com/ViaQ/integration-tests/issues/8
function get_count_from_json_from_search() {
    python -c 'import json, sys; print json.loads(sys.stdin.read()).get("responses", [{}])[0].get("hits", {}).get("total", 0)'
}

# $1 - unique value to search for in es
function add_test_message() {
    local kib_pod=`get_running_pod kibana`
    oc exec $kib_pod -c kibana -- curl --connect-timeout 1 -s \
       http://localhost:5601/$1 > /dev/null 2>&1
}

# $1 - command to call to pass the uuid_es
# $2 - command to call to pass the uuid_es_ops
# $3 - expected number of matches
function wait_for_fluentd_to_catch_up() {
    local starttime=$( date +%s )
    os::log::debug START wait_for_fluentd_to_catch_up at $( date -u --rfc-3339=ns )
    local es_pod=$( get_es_pod es )
    local es_ops_pod=$( get_es_pod es-ops )
    es_ops_pod=${es_ops_pod:-$es_pod}
    local uuid_es=$( uuidgen )
    local uuid_es_ops=$( uuidgen )
    local expected=${3:-1}
    local timeout=${TIMEOUT:-600}
    local project=${4:-logging}

    add_test_message $uuid_es
    os::log::debug added es message $uuid_es
    logger -i -p local6.info -t $uuid_es_ops $uuid_es_ops
    os::log::debug added es-ops message $uuid_es_ops

    local rc=0

    # poll for logs to show up
    local fullmsg="GET /${uuid_es} 404 "
    local qs='{"query":{"match_phrase":{"message":"'"${fullmsg}"'"}}}'
    if os::cmd::try_until_text "curl_es ${es_pod} /project.logging.*/_count -X POST -d '$qs' | get_count_from_json" $expected $(( timeout * second )); then
        os::log::debug good - $FUNCNAME: found $expected record project logging for \'$fullmsg\'
    else
        os::log::error $FUNCNAME: not found $expected record project logging for \'$fullmsg\' after $timeout seconds
        os::log::debug "$( curl_es ${es_pod} /project.logging.*/_search -X POST -d "$qs" )"
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

    qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${uuid_es_ops}"'"}}}'
    if os::cmd::try_until_text "curl_es ${es_ops_pod} /.operations.*/_count -X POST -d '$qs' | get_count_from_json" $expected $(( timeout * second )); then
        os::log::debug good - $FUNCNAME: found $expected record project .operations for $uuid_es_ops
    else
        os::log::error $FUNCNAME: not found $expected record project .operations for $uuid_es_ops after $timeout seconds
        os::log::debug "$( curl_es ${es_ops_pod} /.operations.*/_search -X POST -d "$qs" )"
        os::log::error "Checking journal for $uuid_es_ops..."
        if sudo journalctl | grep -q $uuid_es_ops ; then
            os::log::error "Found $uuid_es_ops in journal"
            os::log::debug "$( sudo journalctl | grep $uuid_es_ops )"
        else
            os::log::error "Unable to find $uuid_es_ops in journal"
        fi
        rc=1
    fi

    if [ -n "${1:-}" ] ; then
        $1 $uuid_es
    fi
    if [ -n "${2:-}" ] ; then
        $2 $uuid_es_ops
    fi
    local endtime=`date +%s`
    os::log::debug END wait_for_fluentd_to_catch_up took `expr $endtime - $starttime` seconds at `date -u --rfc-3339=ns`
    return $rc
}

docker_uses_journal() {
    # note the unintuitive logic - in this case, a 0 return means true, and a 1
    # return means false
    # need to be able to handle cases like
    # OPTIONS='--log-driver=json-file ....' # or use --log-driver=journald
    # if "log-driver" is set in /etc/docker/daemon.json, assume that it is
    # authoritative
    # otherwise, look for /etc/sysconfig/docker
    if type -p docker > /dev/null && sudo docker info | grep -q 'Logging Driver: journald' ; then
        return 0
    elif sudo grep -q '^[^#].*"log-driver":' /etc/docker/daemon.json 2> /dev/null ; then
        if sudo grep -q '^[^#].*"log-driver":.*journald' /etc/docker/daemon.json 2> /dev/null ; then
            return 0
        fi
    elif sudo grep -q "^OPTIONS='[^']*--log-driver=journald" /etc/sysconfig/docker 2> /dev/null ; then
        return 0
    fi
    return 1
}

wait_for_fluentd_ready() {
    local timeout=${1:-60}
    # wait until fluentd is actively reading from the source (journal or files)
    os::cmd::try_until_success "sudo test -f /var/log/journal.pos" $(( timeout * second ))
    if docker_uses_journal ; then
        : # done
    else
        os::cmd::try_until_success "sudo test -f /var/log/es-containers.log.pos" $(( timeout * second ))
    fi
}

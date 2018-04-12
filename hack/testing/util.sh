#!/bin/bash

if ! type -t os::log::info > /dev/null ; then
    source "${OS_O_A_L_DIR:-..}/hack/lib/init.sh"
fi

LOGGING_NS=${LOGGING_NS:-openshift-logging}

function get_es_dcs() {
    oc get dc --selector logging-infra=elasticsearch ${1:+-l component=$1} -o name
}

function get_curator_dcs() {
    oc get dc --selector logging-infra=curator -o name
}

function get_es_pod() {
    # $1 - cluster name postfix
    if [ -z $(oc -n $LOGGING_NS get dc -l cluster-name=logging-${1},es-node-role=clientdata --no-headers | awk '{print $1}') ] ; then
      oc -n $LOGGING_NS get pods -l component=${1} --no-headers | awk '$3 == "Running" {print $1}'
    else
      oc -n $LOGGING_NS get pods -l cluster-name=logging-${1},es-node-role=clientdata --no-headers | awk '$3 == "Running" {print $1}'
    fi
}

function get_es_svc() {
    # $1 - cluster name postfix
    oc -n $LOGGING_NS get svc logging-${1} -o jsonpath='{.metadata.name}'
}

function get_running_pod() {
    # $1 is component for selector
    oc get pods -l component=$1 --no-headers | awk '$3 == "Running" {print $1}'
}

function get_es_cert_path() {

  if [ ! -d "${OS_O_A_L_DIR}/temp/es_certs" ]; then
    mkdir -p ${OS_O_A_L_DIR}/temp/es_certs
    oc extract -n $LOGGING_NS secret/logging-elasticsearch --to=${OS_O_A_L_DIR}/temp/es_certs
  fi

  echo ${OS_O_A_L_DIR}/temp/es_certs
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
# $3 - endpoint (e.g. /projects.*/_search)
# $4 - username
# $5 - token
# stdout is the JSON output from Elasticsearch
# stderr is curl errors
curl_es_from_kibana() {
    local pod="$1"
    local eshost="$2"
    local endpoint="$3"
    local test_name="$4"
    local test_token="$5"
    shift; shift; shift; shift; shift
    local args=( "${@:-}" )

    local secret_dir="/etc/kibana/keys/"
    oc -n $LOGGING_NS exec "${pod}" -c kibana -- curl --connect-timeout 1 --silent --insecure "${args[@]}" \
       --cert "${secret_dir}cert" \
       --key "${secret_dir}key" \
       -H "X-Proxy-Remote-User: $test_name" \
       -H "Authorization: Bearer $test_token" \
       -H "X-Forwarded-For: 127.0.0.1" \
       "https://${eshost}:9200${endpoint}"
}

# $1 - es pod name
# $2 - es endpoint
# rest - any args to pass to curl
function curl_es_pod() {
    local pod="$1"
    local endpoint="$2"
    shift; shift
    local args=( "${@:-}" )

    local secret_dir="/etc/elasticsearch/secret/"
    oc -n $LOGGING_NS exec -c elasticsearch "${pod}" -- curl --silent --insecure "${args[@]}" \
                             --key "${secret_dir}admin-key"   \
                             --cert "${secret_dir}admin-cert" \
                             "https://localhost:9200${endpoint}"
}

# $1 - es svc name
# $2 - es endpoint
# rest - any args to pass to curl
function curl_es() {
    local svc_name="$1"
    local endpoint="$2"
    shift; shift
    local args=( "${@:-}" )

    local secret_dir="$(get_es_cert_path)/"
    curl --silent --insecure "${args[@]}" \
      --key "${secret_dir}/admin-key" \
      --cert "${secret_dir}/admin-cert" \
      "https://${svc_name}.${LOGGING_NS}.svc:9200${endpoint}"
}

# $1 - es svc name
# $2 - es endpoint
# rest - any args to pass to curl
function curl_es_input() {
    local svc_name="$1"
    local endpoint="$2"
    shift; shift
    local args=( "${@:-}" )

    local secret_dir="$(get_es_cert_path)/"
    curl --silent --insecure "${args[@]}" \
      --key "${secret_dir}admin-key"   \
      --cert "${secret_dir}admin-cert" \
      "https://${svc_name}.${LOGGING_NS}.svc:9200${endpoint}"
}

function curl_es_pod_with_token() {
    local pod="$1"
    local endpoint="$2"
    local test_name="$3"
    local test_token="$4"
    shift; shift; shift; shift
    local args=( "${@:-}" )
    oc -n $LOGGING_NS exec -c elasticsearch "${pod}" -- curl --silent --insecure "${args[@]}" \
                             -H "X-Proxy-Remote-User: $test_name" \
                             -H "Authorization: Bearer $test_token" \
                             -H "X-Forwarded-For: 127.0.0.1" \
                             "https://localhost:9200${endpoint}"
}

function curl_es_with_token() {
    local svc_name="$1"
    local endpoint="$2"
    local test_name="$3"
    local test_token="$4"
    shift; shift; shift; shift
    local args=( "${@:-}" )

    curl --silent --insecure "${args[@]}" \
      -H "X-Proxy-Remote-User: $test_name" \
      -H "Authorization: Bearer $test_token" \
      -H "X-Forwarded-For: 127.0.0.1" \
      "https://${svc_name}.${LOGGING_NS}:9200${endpoint}"
}

function curl_es_pod_with_token_and_input() {
    local pod="$1"
    local endpoint="$2"
    local test_name="$3"
    local test_token="$4"
    shift; shift; shift; shift
    local args=( "${@:-}" )

    oc -n $LOGGING_NS exec -c elasticsearch -i "${pod}" -- curl --silent --insecure "${args[@]}" \
                             -H "X-Proxy-Remote-User: $test_name" \
                             -H "Authorization: Bearer $test_token" \
                             -H "X-Forwarded-For: 127.0.0.1" \
                             "https://localhost:9200${endpoint}"
}

function curl_es_with_token_and_input() {
    local svc_name="$1"
    local endpoint="$2"
    local test_name="$3"
    local test_token="$4"
    shift; shift; shift; shift
    local args=( "${@:-}" )

    curl --silent --insecure "${args[@]}" \
      -H "X-Proxy-Remote-User: $test_name" \
      -H "Authorization: Bearer $test_token" \
      -H "X-Forwarded-For: 127.0.0.1" \
      "https://${svc_name}.${LOGGING_NS}:9200${endpoint}"
}

# $1 - es pod name
# $2 - index name (e.g. project.logging, project.test, .operations, etc.)
# $3 - _count or _search
# $4 - field to search
# $5 - search string
# stdout is the JSON output from Elasticsearch
# stderr is curl errors
function query_es_from_es() {
    curl_es_pod "$1" "/${2}*/${3}?q=${4}:${5}" --connect-timeout 1
}

# $1 is es svc
# $2 is timeout
function wait_for_es_ready() {
    # test for ES to be up first and that our SG index has been created
    echo "Checking if Elasticsearch $1 is ready"
    secret_dir="$(get_es_cert_path)/"
    local ii=$2
    local path=${3:-.searchguard.$1}
    while ! response_code=$(curl -s \
        --request HEAD --head --output /dev/null \
        --cacert $secret_dir/admin-ca \
        --cert $secret_dir/admin-cert \
        --key  $secret_dir/admin-key \
        --connect-timeout 1 \
        -w '%{response_code}' \
        "https://${1}.${LOGGING_NS}:9200/$path") || test "${response_code:-}" != 200
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
    oc -n $LOGGING_NS exec $kib_pod -c kibana -- curl --connect-timeout 1 -s \
       http://localhost:5601/$1 > /dev/null 2>&1
}

function flush_fluentd_pos_files() {
    os::cmd::expect_success "sudo rm -f /var/log/journal.pos"
}

# $1 - command to call to pass the uuid_es
# $2 - command to call to pass the uuid_es_ops
# $3 - expected number of matches
function wait_for_fluentd_to_catch_up() {
    local starttime=$( date +%s.%9N )
    local startsecs=$( date --date=@${starttime} +%s )
    local tsprefix=$( date --date=@${startsecs} "+%Y%m%d%H%M%S" )
    os::log::debug START wait_for_fluentd_to_catch_up at $( date --date=@${starttime} -u --rfc-3339=ns )
    local es_svc=$( get_es_svc es )
    local es_ops_svc=$( get_es_svc es-ops )
    es_ops_svc=${es_ops_svc:-$es_svc}
    local uuid_es=$( uuidgen | sed 's/[-]//g' )
    local uuid_es_ops=$( uuidgen | sed 's/[-]//g' )
    local expected=${3:-1}
    local timeout=${TIMEOUT:-600}
    local appsproject=${4:-$LOGGING_NS}
    local priority=${TEST_REC_PRIORITY:-info}

    wait_for_fluentd_ready

    # look for the messages in the source
    local fullmsg="GET /${uuid_es} 404 "
    local using_journal=0
    local checkpids
    if docker_uses_journal ; then
        using_journal=1
        sudo journalctl -f -o export | \
            awk -v es=$uuid_es -v es_ops=$uuid_es_ops \
            -v es_out=$ARTIFACT_DIR/es_out.txt -v es_ops_out=$ARTIFACT_DIR/es_ops_out.txt '
                BEGIN{RS="";FS="\n"};
                $0 ~ es {print > es_out; found += 1};
                $0 ~ es_ops {print > es_ops_out; found += 1};
                {if (found == 2) {exit 0}}' > /dev/null 2>&1 & checkpids=$!
    else
        sudo journalctl -f -o export | \
            awk -v es_ops=$uuid_es_ops -v es_ops_out=$ARTIFACT_DIR/es_ops_out.txt '
                BEGIN{RS="";FS="\n"};
                $0 ~ es_ops {print > es_ops_out; exit 0}' > /dev/null 2>&1 & checkpids=$!
        while ! sudo find /var/log/containers -name \*.log -exec grep -b -n "$fullmsg" {} /dev/null \; > $ARTIFACT_DIR/es_out.txt ; do
            sleep 1
        done & checkpids="$checkpids $!"
    fi

    add_test_message $uuid_es
    artifact_log added es message $uuid_es
    logger -i -p local6.${priority} -t $uuid_es_ops $uuid_es_ops
    artifact_log added es-ops message $uuid_es_ops

    local errqs
    local rc=0
    local qs='{"query":{"bool":{"filter":{"match_phrase":{"message":"'"${fullmsg}"'"}},"must":{"term":{"kubernetes.container_name":"kibana"}}}}}'
    case "${appsproject}" in
    default|openshift|openshift-*) logging_index=".operations.*" ; es_svc=$es_ops_svc ;;
    *) logging_index="project.${appsproject}.*" ;;
    esac

    # poll for logs to show up
    if os::cmd::try_until_text "curl_es ${es_svc} /${logging_index}/_count -X POST -d '$qs' | get_count_from_json" $expected $(( timeout * second )); then
        artifact_log good - $FUNCNAME: found $expected record $logging_index for \'$fullmsg\'
        if [ -n "${1:-}" ] ; then
            curl_es ${es_svc} "/${logging_index}/_search" -X POST -d "$qs" | jq . > $ARTIFACT_DIR/apps.json
            $1 $uuid_es $ARTIFACT_DIR/apps.json
        fi
    else
        os::log::error $FUNCNAME: not found $expected record $logging_index for \'$fullmsg\' after $timeout seconds
        curl_es ${es_svc} /${logging_index}/_search -X POST -d "$qs" > $ARTIFACT_DIR/apps_search_output.raw 2>&1 || :
        if [ -s $ARTIFACT_DIR/es_out.txt ] ; then
            os::log::error "$( cat $ARTIFACT_DIR/es_out.txt )"
        else
            os::log::error apps record for "$fullmsg" not found in source
        fi
        if sudo test -f /var/log/es-containers.log.pos ; then
            os::log::error here are the current container log positions
            sudo cat /var/log/es-containers.log.pos
        fi
        os::log::error here is the current fluentd journal cursor
        sudo cat /var/log/journal.pos
        # records since start of function
        errqs='{"query":{"range":{"@timestamp":{"gte":"'"$( date --date=@${starttime} -u --Ins )"'"}}}}'
        curl_es ${es_pod} /${logging_index}/_search -X POST -d "$errqs" | jq . > $ARTIFACT_DIR/apps_err_recs.json 2>&1 || :
        rc=1
    fi

    qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${uuid_es_ops}"'"}}}'
    if os::cmd::try_until_text "curl_es ${es_ops_svc} /.operations.*/_count -X POST -d '$qs' | get_count_from_json" $expected $(( timeout * second )); then
        os::log::debug good - $FUNCNAME: found $expected record .operations for $uuid_es_ops
        if [ -n "${2:-}" ] ; then
            curl_es ${es_ops_svc} "/.operations.*/_search" -X POST -d "$qs" | jq . > $ARTIFACT_DIR/ops.json
            $2 $uuid_es_ops $ARTIFACT_DIR/ops.json
        fi
    else
        os::log::error $FUNCNAME: not found $expected record .operations for $uuid_es_ops after $timeout seconds
        curl_es ${es_ops_svc} /.operations.*/_search -X POST -d "$qs" > $ARTIFACT_DIR/apps_search_output.raw 2>&1 || :
        os::log::error "Checking journal for $uuid_es_ops..."
        if [ -s $ARTIFACT_DIR/es_ops_out.txt ] ; then
            os::log::error "$( cat $ARTIFACT_DIR/es_ops_out.txt )"
        else
            os::log::error ops record for "$uuid_es_ops" not found in journal
        fi
        os::log::error here is the current fluentd journal cursor
        sudo cat /var/log/journal.pos
        # records since start of function
        errqs='{"query":{"range":{"@timestamp":{"gte":"'"$( date --date=@${starttime} -u --Ins )"'"}}}}'
        curl_es ${es_ops_pod} /.operations.*/_search -X POST -d "$errqs" | jq . > $ARTIFACT_DIR/ops_err_recs.json 2>&1 || :
        rc=1
    fi

    kill $checkpids > /dev/null 2>&1 || :
    kill -9 $checkpids > /dev/null 2>&1 || :

    local endtime=$( date +%s.%9N )
    local endsecs=$( date --date=@${endtime} +%s )
    os::log::debug END wait_for_fluentd_to_catch_up took $( expr $endsecs - $startsecs ) seconds at $( date --date=@${endtime} -u --rfc-3339=ns )
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
    if type -p docker > /dev/null && sudo docker info 2>&1 | grep -q 'Logging Driver: journald' ; then
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

extra_artifacts_testname=$( basename $0 )
extra_artifacts=$ARTIFACT_DIR/${extra_artifacts_testname}-artifacts.txt
internal_artifact_log() {
    local ts=$1 ; shift
    echo \[${ts}\] "$@" >> $extra_artifacts
}
artifact_log() {
    internal_artifact_log "$( date +%Y-%m-%dT%H:%M:%S.%3N%z )" "$@"
}
artifact_out() {
    local ts="$( date +%Y-%m-%dT%H:%M:%S.%3N%z )"
    local line
    while IFS= read -r line ; do
        internal_artifact_log "${ts}" "$line"
    done
}

# e.g. 2 or 5 or 6
get_es_major_ver() {
    local es_svc=$( get_es_svc es )
    curl_es $es_svc "/" | jq -r '.version.number | split(".")[0]'
}

# fields are given like this: c a r s q
get_bulk_thread_pool_url() {
    local es_ver=$1
    local headers=$2
    shift; shift
    # remaining args are fields
    local url="/_cat/thread_pool"
    local comma=""
    local pref=""

    if [ "${es_ver}" -gt 2 ] ; then
        url="${url}/bulk"
    else
        pref="b"
    fi
    url="${url}?"
    if [ -n "${headers}" ] ; then
        url="${url}v&h="
    else
        url="${url}h="
    fi
    while [ -n "${1:-}" ] ; do
        url="${url}${comma}${pref}$1"
        comma=,
        shift
    done
    echo $url
}

#!/bin/bash

if ! type -t os::log::info > /dev/null ; then
    source "${OS_O_A_L_DIR:-..}/hack/lib/init.sh"
fi

function generate_JKS_chain() {
    dir=${SCRATCH_DIR:-_output}
    ADD_OID=$1
    NODE_NAME=$2
    CERT_NAMES=${3:-$NODE_NAME}
    ks_pass=${KS_PASS:-kspass}
    ts_pass=${TS_PASS:-tspass}
    rm -rf $NODE_NAME

    extension_names=""
    for name in ${CERT_NAMES//,/ }; do
        extension_names="${extension_names},dns:${name}"
    done

    if [ "$ADD_OID" = true ]; then
        extension_names="${extension_names},oid:1.2.3.4.5.5"
    fi

    echo Generating keystore and certificate for node $NODE_NAME

    "$keytool" -genkey \
        -alias     $NODE_NAME \
        -keystore  $dir/keystore.jks \
        -keypass   $ks_pass \
        -storepass $ks_pass \
        -keyalg    RSA \
        -keysize   2048 \
        -validity  712 \
        -dname "CN=$NODE_NAME, OU=OpenShift, O=Logging" \
        -ext san=dns:localhost,ip:127.0.0.1"${extension_names}"

    echo Generating certificate signing request for node $NODE_NAME

    "$keytool" -certreq \
        -alias      $NODE_NAME \
        -keystore   $dir/keystore.jks \
        -storepass  $ks_pass \
        -file       $dir/$NODE_NAME.csr \
        -keyalg     rsa \
        -dname "CN=$NODE_NAME, OU=OpenShift, O=Logging" \
        -ext san=dns:localhost,ip:127.0.0.1"${extension_names}"

    echo Sign certificate request with CA

    openssl ca \
        -in $dir/$NODE_NAME.csr \
        -notext \
        -out $dir/$NODE_NAME.crt \
        -config $dir/signing.conf \
        -extensions v3_req \
        -batch \
        -extensions server_ext

    echo "Import back to keystore (including CA chain)"

    "$keytool"  \
        -import \
        -file $dir/ca.crt  \
        -keystore $dir/keystore.jks   \
        -storepass $ks_pass  \
        -noprompt -alias sig-ca

    "$keytool" \
        -import \
        -file $dir/$NODE_NAME.crt \
        -keystore $dir/keystore.jks \
        -storepass $ks_pass \
        -noprompt \
        -alias $NODE_NAME

    echo "Import CA to truststore for validating client certs"

    "$keytool"  \
        -import \
        -file $dir/ca.crt  \
        -keystore $dir/truststore.jks   \
        -storepass $ts_pass  \
	-trustcacerts \
        -noprompt -alias sig-ca

    echo All done for $NODE_NAME
}

function generate_PEM_cert() {
    NODE_NAME="$1"
    dir=${SCRATCH_DIR:-_output}  # for writing files to bundle into secrets

    echo Generating keystore and certificate for node ${NODE_NAME}

    openssl req -out "$dir/$NODE_NAME.csr" -new -newkey rsa:2048 -keyout "$dir/$NODE_NAME.key" -subj "/CN=$NODE_NAME/OU=OpenShift/O=Logging" -days 712 -nodes

    echo Sign certificate request with CA
    openssl ca \
        -in "$dir/$NODE_NAME.csr" \
        -notext \
        -out "$dir/$NODE_NAME.crt" \
        -config $dir/signing.conf \
        -extensions v3_req \
        -batch \
        -extensions server_ext
}

function generate_JKS_client_cert() {
    NODE_NAME="$1"
    ks_pass=${KS_PASS:-kspass}
    ts_pass=${TS_PASS:-tspass}
    dir=${SCRATCH_DIR:-_output}  # for writing files to bundle into secrets

    echo Generating keystore and certificate for node ${NODE_NAME}

    "$keytool" -genkey \
        -alias     $NODE_NAME \
        -keystore  $dir/$NODE_NAME.jks \
        -keyalg    RSA \
        -keysize   2048 \
        -validity  712 \
        -keypass $ks_pass \
        -storepass $ks_pass \
        -dname "CN=$NODE_NAME, OU=OpenShift, O=Logging"

    echo Generating certificate signing request for node $NODE_NAME

    "$keytool" -certreq \
        -alias      $NODE_NAME \
        -keystore   $dir/$NODE_NAME.jks \
        -file       $dir/$NODE_NAME.csr \
        -keyalg     rsa \
        -keypass $ks_pass \
        -storepass $ks_pass \
        -dname "CN=$NODE_NAME, OU=OpenShift, O=Logging"

    echo Sign certificate request with CA
    openssl ca \
        -in "$dir/$NODE_NAME.csr" \
        -notext \
        -out "$dir/$NODE_NAME.crt" \
        -config $dir/signing.conf \
        -extensions v3_req \
        -batch \
        -extensions server_ext

    echo "Import back to keystore (including CA chain)"

    "$keytool"  \
        -import \
        -file $dir/ca.crt  \
        -keystore $dir/$NODE_NAME.jks   \
        -storepass $ks_pass  \
        -noprompt -alias sig-ca

    "$keytool" \
        -import \
        -file $dir/$NODE_NAME.crt \
        -keystore $dir/$NODE_NAME.jks \
        -storepass $ks_pass \
        -noprompt \
        -alias $NODE_NAME

    echo All done for $NODE_NAME
}

function join { local IFS="$1"; shift; echo "$*"; }

function get_es_dcs() {
    oc get dc --selector logging-infra=elasticsearch -o name
}

function get_curator_dcs() {
    oc get dc --selector logging-infra=curator -o name
}

function extract_nodeselector() {
    local inputstring="${1//\"/}"  # remove any errant double quotes in the inputs
    local selectors=()

    for keyvalstr in ${inputstring//\,/ }; do

        keyval=( ${keyvalstr//=/ } )

        if [[ -n "${keyval[0]}" && -n "${keyval[1]}" ]]; then
            selectors+=( "\"${keyval[0]}\": \"${keyval[1]}\"")
        else
            echo "Could not make a node selector label from '${keyval[*]}'"
            exit 255
        fi
    done

    if [[ "${#selectors[*]}" -gt 0 ]]; then
        echo nodeSelector: "{" $(join , "${selectors[@]}") "}"
    fi
}

function wait_for_latest_build_complete() {

  interval=30
  waittime=120

  local bc=$1
  local lastVersion=$(oc get bc $bc -o jsonpath='{.status.lastVersion}')
  local status

  for (( i = 1; i <= $waittime; i++ )); do
    status=$(oc get build/$bc-$lastVersion -o jsonpath='{.status.phase}')
    case $status in
      "Complete")
        return 0
        ;;
      "Failed")
        return 1
        ;;
      "Pending"|"Running")
        sleep $interval
        ;;
    esac
  done

  return 1
}

function wait_for_new_builds_complete() {

  retries=30
  for bc in $(oc get bc -l logging-infra -o jsonpath='{.items[*].metadata.name}'); do

    for (( i = 1; i <= retries; i++ )); do

      wait_for_latest_build_complete "$bc" && break

      [[ $i -eq $retries ]] && return 1

      oc delete builds -l buildconfig=$bc

      if [ "$USE_LOCAL_SOURCE" = false ] ; then
          oc start-build $bc
      else
          oc start-build --from-dir $OS_O_A_L_DIR $bc
      fi
    done

  done

  return 0
}

function wait_for_builds_complete()
{
    waittime=3600 # seconds - 1 hour
    interval=60
    complete=0
    while [ $waittime -gt 0 -a $complete = 0 ] ; do
        # all lines must have $4 == "Complete"
        complete=`oc get builds | awk '$4 == "STATUS" || $4 == "Complete" {complete++}; END {print NR == complete}'`
        if [ $complete = 1 ] ; then
            echo Builds are complete
            break
        fi
        # restart failed builds
        # get a list of the new failures
        curfailedbuilds=`oc get builds | awk '$4 == "Failed" {print $1}'`
        for build in $curfailedbuilds ; do
            # get the bc
            bc=`oc get build $build --template='{{.metadata.labels.buildconfig}}'`
            # see if there is a build in progress for this bc
            statuses=`oc describe bc $bc | awk -v pre=$bc '$1 ~ pre {print $2}'`
            needbuild=0
            for status in $statuses ; do
                case $status in
                "running"|"complete"|"pending")
                    echo build in progress for $bc - delete failed build $build status $status
                    # delete the failed build - otherwise it will show up in the list and
                    # the main loop will never Complete
                    oc logs build/$build > $LOG_DIR/build-$build.log 2>&1
                    oc delete build $build
                    needbuild=0
                    break
                    ;;
                "failed")
                    # if the build failed, there will be at least 1 failed status
                    # if there is another build running or complete, it will be
                    # detected above
                    needbuild=1
                    ;;
                esac
            done
            # if we are here and needbuild=1, there were no running or complete builds
            if [ $needbuild = "1" ] ; then
                # start a new build
                if [ "$USE_LOCAL_SOURCE" = false ] ; then
                    oc start-build $bc
                else
                    oc start-build --from-dir $OS_O_A_L_DIR $bc
                fi
            fi
        done
        sleep $interval
        waittime=`expr $waittime - $interval` || :
    done
    if [ $complete = 0 ] ; then
        echo error builds are not complete
        oc get builds
        return 1
    fi
    return 0
}

get_error_pod() {
    # $1 is component for selector
    oc get pods -l component=$1 | awk -v sel=$1 '$1 ~ sel && ($3 == "Error" || $3 == "CrashLoopBackOff") {print $1}'
}

wait_for_pod_ACTION() {
    # action is $1 - start or stop
    # $2 - if action is stop, $2 is the pod name
    #    - if action is start, $2 is the component selector
    # $3 - if present, expect error - if stop, $2 may be empty, just return - if start, no error if pod cannot be started
    local ii=120
    local incr=10
    if [ $1 = start ] ; then
        curpod=`get_running_pod $2`
    else
        curpod=${2:-}
        if [ -z "${curpod:-}" -a -n "${3:-}" ] ; then
            return 0 # assume not running
        fi
    fi
    while [ $ii -gt 0 ] ; do
        if [ $1 = stop ] && oc describe pod/$curpod > /dev/null 2>&1 ; then
            if [ -n "${VERBOSE:-}" ] ; then
                echo pod $curpod still running
            fi
        elif [ $1 = start ] && [ -z "$curpod" ] ; then
            if [ -n "${3:-}" ] ; then
                errpod=`get_error_pod $2`
                if [ -n "$errpod" ] ; then
                    return 1
                fi
            fi
            if [ -n "${VERBOSE:-}" ] ; then
                echo pod for component=$2 not running yet
            fi
        else
            break # pod is either started or stopped
        fi
        sleep $incr
        ii=`expr $ii - $incr` || :
        if [ $1 = start ] ; then
            curpod=`get_running_pod $2`
        fi
    done
    if [ $ii -le 0 ] ; then
        echo ERROR: pod $2 not in state $1 after 2 minutes
        oc get pods
        return 1
    fi
    return 0
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

function get_latest_pod() {

  label=$1

  local times=(`oc get pods -l $label -o jsonpath='{.items[*].metadata.creationTimestamp}' | xargs -n1 | sort -r | xargs`)
  local pod=$(oc get pods -l $label -o jsonpath="{.items[?(@.metadata.creationTimestamp==\"${times[0]}\")].metadata.name}")

  echo $pod
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
       https://${2}:9200/${3}*/${4}\?q=${5}:${6}
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
    oc exec "${pod}" -- curl --silent --insecure "${args[@]}" \
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
    oc exec -i "${pod}" -- curl --silent --insecure "${args[@]}" \
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
    oc exec "${pod}" -- curl --silent --insecure "${args[@]}" \
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
    oc exec -i "${pod}" -- curl --silent --insecure "${args[@]}" \
                                -H "X-Proxy-Remote-User: $test_name" \
                                -H "Authorization: Bearer $test_token" \
                                -H "X-Forwarded-For: 127.0.0.1" \
                                "https://localhost:9200${endpoint}"
}

# $1 - es pod name
# $2 - es hostname (e.g. logging-es or logging-es-ops)
# $3 - index name (e.g. project.logging, project.test, .operations, etc.)
# $4 - _count or _search
# $5 - field to search
# $6 - search string
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
    while ! response_code=$(oc exec $1 -- curl -s -X HEAD \
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

# $1 - shell command or function to call to test if wait is over -
#      this command/function should return true if the condition
#      has been met, or false if still waiting for condition to be met
# $2 - shell command or function to call if we timed out for error handling
# $3 - timeout in seconds - should be a multiple of $4 (interval)
# $4 - loop interval in seconds
function wait_until_cmd_or_err() {
    let ii=$3
    local interval=${4:-1}
    while [ $ii -gt 0 ] ; do
        $1 && break
        sleep $interval
        let ii=ii-$interval
    done
    if [ $ii -le 0 ] ; then
        $2
        return 1
    fi
    return 0
}

# return true if the actual count matches the expected count, false otherwise
function test_count_expected() {
    myfield=${myfield:-message}
    local nrecs=`query_es_from_es $espod $myproject _count $myfield $mymessage | \
           get_count_from_json`
    test "$nrecs" = $expected
}

# display an appropriate error message if the expected count did not match
# the actual count
function test_count_err() {
    myfield=${myfield:-message}
    nrecs=`query_es_from_es $espod $myproject _count $myfield $mymessage | \
           get_count_from_json`
    os::log::error found $nrecs for project $myproject message $mymessage - expected $expected
    for thetype in _count _search ; do
        query_es_from_es $espod $myproject $thetype $myfield $mymessage | python -mjson.tool
    done
}

# $1 - command to call to pass the uuid_es
# $2 - command to call to pass the uuid_es_ops
# $3 - expected number of matches
function wait_for_fluentd_to_catch_up() {
    local starttime=`date +%s`
    os::log::debug START wait_for_fluentd_to_catch_up at `date -u --rfc-3339=ns`
    local es_pod=`get_es_pod es`
    local es_ops_pod=`get_es_pod es-ops`
    if [ -z "$es_ops_pod" ] ; then
        es_ops_pod=$es_pod
    fi
    local uuid_es=`uuidgen`
    local uuid_es_ops=`uuidgen`
    local expected=${3:-1}
    local timeout=300
    local project=${4:-logging}

    add_test_message $uuid_es
    os::log::debug added es message $uuid_es
    logger -i -p local6.info -t $uuid_es_ops $uuid_es_ops
    os::log::debug added es-ops message $uuid_es_ops

    local rc=0

    # poll for logs to show up

    if espod=$es_pod myproject=project.$project mymessage=$uuid_es expected=$expected \
            wait_until_cmd_or_err test_count_expected test_count_err $timeout ; then
        os::log::debug good - $FUNCNAME: found $expected record project logging for $uuid_es
    else
        os::log::error $FUNCNAME: not found $expected record project logging for $uuid_es after $timeout seconds
        os::log::error "Checking journal for $uuid_es..."
        if sudo journalctl | grep -q $uuid_es ; then
            os::log::error "Found $uuid_es in journal"
            os::log::debug "$( sudo journalctl | grep $uuid_es )"
        else
            os::log::error "Unable to find $uuid_es in journal"
        fi

        rc=1
    fi

    if espod=$es_ops_pod myproject=.operations mymessage=$uuid_es_ops expected=$expected myfield=systemd.u.SYSLOG_IDENTIFIER \
            wait_until_cmd_or_err test_count_expected test_count_err $timeout ; then
        os::log::debug good - $FUNCNAME: found $expected record project .operations for $uuid_es_ops
    else
        os::log::error $FUNCNAME: not found $expected record project .operations for $uuid_es_ops after $timeout seconds
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
    elif grep -q '^[^#].*"log-driver":' /etc/docker/daemon.json 2> /dev/null ; then
        if grep -q '^[^#].*"log-driver":.*journald' /etc/docker/daemon.json 2> /dev/null ; then
            return 0
        fi
    elif grep -q "^OPTIONS='[^']*--log-driver=journald" /etc/sysconfig/docker 2> /dev/null ; then
        return 0
    fi
    return 1
}

wait_for_fluentd_ready() {
    # wait until fluentd is actively reading from the source (journal or files)
    if docker_uses_journal ; then
        journal_pos_err() {
            os::log::error timed out waiting for /var/log/journal.pos - check Fluentd pod log
            return 1
        }
        if wait_until_cmd_or_err "test -f /var/log/journal.pos" journal_pos_err ${1:-60} ; then
            return 0
        fi
    else
        node_pos_err() {
            os::log::error timed out waiting for /var/log/node.log.pos - check Fluentd pod log
            return 1
        }
        if wait_until_cmd_or_err "test -f /var/log/node.log.pos" node_pos_err ${1:-60} ; then
            cont_pos_err() {
                os::log::error timed out waiting for /var/log/es-containers.log.pos - check Fluentd pod log
                return 1
            }
            if wait_until_cmd_or_err "test -f /var/log/es-containers.log.pos" cont_pos_err ${1:-60} ; then
                return 0
            fi
        fi
    fi
    return 1
}

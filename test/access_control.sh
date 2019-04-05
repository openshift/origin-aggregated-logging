#!/bin/bash

# test access control
source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
trap os::test::junit::reconcile_output EXIT
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/access_control"

LOGGING_NS=${LOGGING_NS:-openshift-logging}

espod=$( get_es_pod es )
esopspod=$( get_es_pod es-ops )
esopspod=${esopspod:-$espod}
es_svc=$( get_es_svc es )
es_ops_svc=$( get_es_svc es-ops )
es_ops_svc=${es_ops_svc:-$es_svc}

# enable debug logging for searchguard and o-e-plugin
#curl_es $es_svc /_cluster/settings -XPUT -d '{"transient":{"logger.com.floragunn.searchguard":"TRACE","logger.io.fabric8.elasticsearch":"TRACE"}}'

delete_users=""
REUSE=${REUSE:-false}

function check_es_acls() {
  local doc=""
  local ts=$( date +%s )
  for doc in roles rolesmapping actiongroups; do
    artifact_log Checking that Elasticsearch pod ${espod} has expected acl definitions $ARTIFACT_DIR/$doc.$ts
    oc exec -c elasticsearch ${espod} -- es_acl get --doc=${doc} > $ARTIFACT_DIR/$doc.$ts 2>&1
  done
}

function cleanup() {
    local result_code="$?"
    set +e
    if [ "${REUSE:-false}" = false ] ; then
        for user in $delete_users ; do
            oc delete user $user 2>&1 | artifact_out
        done
    fi
    if [ "$result_code" != 0 -a -n "${test_message:-}" ] ; then
        os::log::error $test_message
        cat $ARTIFACT_DIR/curl-raw.out $ARTIFACT_DIR/curl-verbose.out
        if [ -f $ARTIFACT_DIR/curl-pretty.out ] ; then
            cat $ARTIFACT_DIR/curl-pretty.out
        fi
    fi
    if [ -n "${espod:-}" ] ; then
        check_es_acls
        oc logs -c elasticsearch $espod > $ARTIFACT_DIR/es.log
        oc exec -c elasticsearch $espod -- logs >> $ARTIFACT_DIR/es.log
        curl_es_pod $espod /project.access-control-* -XDELETE > /dev/null
    fi
    for proj in access-control-1 access-control-2 access-control-3 ; do
        oc delete project $proj 2>&1 | artifact_out
        os::cmd::try_until_failure "oc get project $proj" 2>&1 | artifact_out
    done
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $result_code
}

trap cleanup EXIT

function create_user_and_assign_to_projects() {
    local current_project; current_project="$( oc project -q )"
    local user=$1; shift
    local pw=$1; shift
    if oc get users $user > /dev/null 2>&1 ; then
        os::log::info Using existing user $user
    else
        os::log::info Creating user $user with password $pw
        create_users "$user" "$pw" false 2>&1 | artifact_out
        delete_users="$delete_users $user"
    fi
    os::log::info Assigning user to projects "$@"
    while [ -n "${1:-}" ] ; do
        oc project $1 2>&1 | artifact_out
        oc adm policy add-role-to-user view $user 2>&1 | artifact_out
        shift
    done
    oc project "${current_project}" > /dev/null
}

function add_message_to_index() {
    # project is $1
    # message is $2
    # espod is $3
    local project_uuid=$( oc get project $1 -o jsonpath='{ .metadata.uid }' )
    local index="project.$1.$project_uuid.$(date -u +'%Y.%m.%d')"
    local espod=$3
    curl_es_pod "$espod" "/$index/access-control-test/" -XPOST -d '{"message":"'${2:-"access-control message"}'"}' | python -mjson.tool 2>&1 | artifact_out
    curl_es_pod "$espod" /_cat/indices 2>&1 | artifact_out || :
    curl_es_pod "$espod" "/$index/_search?pretty" 2>&1 | artifact_out || :
}

function run_curl_cmd() {
    local expected_status="$1" ; shift
    "$@" -v --connect-timeout 10 --max-time 10 1> $ARTIFACT_DIR/curl-raw.out 2> $ARTIFACT_DIR/curl-verbose.out
    cat $ARTIFACT_DIR/curl-raw.out | python -mjson.tool > $ARTIFACT_DIR/curl-pretty.out 2>&1 || :
    local status=$( awk '/^< HTTP[/]1.1 / {print $3}' $ARTIFACT_DIR/curl-verbose.out )
    cat $ARTIFACT_DIR/curl-raw.out
    test $status = $expected_status
}

# test the following
# - regular user can access with token
#   - directly against es
#   - via kibana pod with kibana cert/key
# - regular user cannot access unavailable indices
#   - directly against es
#   - via kibana pod with kibana cert/key
# - regular user cannot access .operations
#   - via es or kibana
#   - with no token
#   - with bogus token
function test_user_has_proper_access() {
    local user=$1; shift
    local pw=$1; shift
    # rest - indices to which access should be granted, followed by --,
    # followed by indices to which access should not be granted
    local expected=1
    local expected_status=200
    local verb=cannot
    local negverb=can
    local kpod=$( get_running_pod kibana )
    local eshost=$( get_es_svc es )
    local esopshost=$( get_es_svc es-ops )
    if [ "$espod" = "$esopspod" ] ; then
        esopshost=$eshost
    fi
    get_test_user_token $user $pw false
    for proj in "$@" ; do
        if [ "$proj" = "--" ] ; then
            expected=0
            verb=can
            negverb=cannot
            expected_status=403
            continue
        fi
        os::log::info See if user $user $negverb read /project.$proj.*
        os::log::info Checking access directly against ES pod...
        test_message="$user $verb access project.$proj.* indices from es"
        curl_es_pod $espod "/project.$proj.*/_count?pretty"
        os::cmd::expect_success_and_text \
            "run_curl_cmd $expected_status curl_es_pod_with_token $espod '/project.$proj.*/_count' $test_token | get_count_from_json" \
            "^$expected\$"

        os::log::info Checking access from Kibana pod...
        test_message="$user $verb access project.$proj.* indices from kibana"
        os::cmd::expect_success_and_text \
            "run_curl_cmd $expected_status curl_es_from_kibana $kpod $eshost '/project.$proj.*/_count' $test_token | get_count_from_json" \
            "^$expected\$"

        if [ "$expected" = 1 ] ; then
            # make sure no access with incorrect auth
            # bogus token
            os::log::info Checking access providing bogus token
            test_message="invalid access from es with BOGUS token"
            os::cmd::expect_success "run_curl_cmd 401 curl_es_pod_with_token $espod '/project.$proj.*/_count' BOGUS"

            test_message="invalid access from kibana with BOGUS token"
            os::cmd::expect_success "run_curl_cmd 403 curl_es_from_kibana $kpod $eshost '/project.$proj.*/_count' BOGUS"

            # no token
            os::log::info Checking access providing no username or token
            test_message="invalid access from es with no token"
            os::cmd::expect_success "run_curl_cmd 401 curl_es_pod_with_token $espod '/project.$proj.*/_count' ''"

            test_message="invalid access from kibana with no token"
            os::cmd::expect_success "run_curl_cmd 403 curl_es_from_kibana $kpod $eshost '/project.$proj.*/_count' ''"
        fi
    done

    test_message="$user has improper access to .operations.* indices from es"
    os::cmd::expect_success_and_text \
        "run_curl_cmd 403 curl_es_pod_with_token $esopspod '/.operations.*/_count' $test_token | get_count_from_json" \
        "^0\$"

    esopshost=$( get_es_svc es-ops )
    if [ "$espod" = "$esopspod" ] ; then
        esopshost=$( get_es_svc es )
    fi
    test_message="$user has improper access to .operations.* indices from kibana"
    os::cmd::expect_success_and_text \
        "run_curl_cmd 403 curl_es_from_kibana $kpod $esopshost '/.operations.*/_count' $test_token | get_count_from_json" \
        "^0\$"

    test_message="$user has improper access to .operations.* indices from es with no token"
    os::cmd::expect_success_and_text \
        "run_curl_cmd 401 curl_es_pod_with_token $esopspod '/.operations.*/_count' '' | get_count_from_json" \
        "^0\$"

    test_message="$user has improper access to .operations.* indices from kibana with no token"
    os::cmd::expect_success_and_text \
        "run_curl_cmd 403 curl_es_from_kibana $kpod $esopshost '/.operations.*/_count' '' | get_count_from_json" \
        "^0\$"

    test_message="$user has improper access to .operations.* indices from es with BOGUS token"
    os::cmd::expect_success_and_text \
        "run_curl_cmd 401 curl_es_pod_with_token $esopspod '/.operations.*/_count' BOGUS | get_count_from_json" \
        "^0\$"

    test_message="$user has improper access to .operations.* indices from kibana with BOGUS token"
    os::cmd::expect_success_and_text \
        "run_curl_cmd 403 curl_es_from_kibana $kpod $esopshost '/.operations.*/_count' BOGUS | get_count_from_json" \
        "^0\$"
    test_message=""
}

curl_es_pod $espod /project.access-control-* -XDELETE 2>&1 | artifact_out

for proj in access-control-1 access-control-2 access-control-3 ; do
    os::log::info Creating project $proj
    oc adm new-project $proj --node-selector='' 2>&1 | artifact_out
    os::cmd::try_until_success "oc get project $proj" 2>&1 | artifact_out

    os::log::info Creating test index and entry for $proj
    add_message_to_index $proj "" $espod
done

LOG_ADMIN_USER=${LOG_ADMIN_USER:-admin}
LOG_ADMIN_PW=${LOG_ADMIN_PW:-admin}

# if you ever want to run this test again on the same machine, you'll need to
# use different usernames, otherwise you'll get this odd error:
# # oc login --username=loguser --password=loguser
# error: The server was unable to respond - verify you have provided the correct host and port and that the server is currently running.
# or - set REUSE=true
LOG_NORMAL_USER=${LOG_NORMAL_USER:-loguserac-$RANDOM}
LOG_NORMAL_PW=${LOG_NORMAL_PW:-loguserac-$RANDOM}

LOG_USER2=${LOG_USER2:-loguser2ac-$RANDOM}
LOG_PW2=${LOG_PW2:-loguser2ac-$RANDOM}

create_users $LOG_NORMAL_USER $LOG_NORMAL_PW false $LOG_USER2 $LOG_PW2 false $LOG_ADMIN_USER $LOG_ADMIN_PW true 2>&1 | artifact_out

os::log::info workaround access_control admin failures - sleep 60 seconds to allow system to process cluster role setting
sleep 60
oc auth can-i '*' '*' --user=$LOG_ADMIN_USER 2>&1 | artifact_out
oc get users 2>&1 | artifact_out

create_user_and_assign_to_projects $LOG_NORMAL_USER $LOG_NORMAL_PW access-control-1 access-control-2
create_user_and_assign_to_projects $LOG_USER2 $LOG_PW2 access-control-2 access-control-3

oc login --username=system:admin > /dev/null
oc project ${LOGGING_NS} > /dev/null

test_user_has_proper_access $LOG_NORMAL_USER $LOG_NORMAL_PW access-control-1 access-control-2 -- access-control-3
test_user_has_proper_access $LOG_USER2 $LOG_PW2 access-control-2 access-control-3 -- access-control-1

logging_index=".operations.*"
if [ ${LOGGING_NS} = "logging" ] ; then
    logging_index="project.logging.*"
fi

os::log::info now auth using admin + token
get_test_user_token $LOG_ADMIN_USER $LOG_ADMIN_PW true
if [ ${LOGGING_NS} = "logging" ] && [ $espod != $esopspod ] ; then
    test_message="admin user can access ${logging_index} indices from es"
    os::cmd::expect_success_and_not_text \
        "run_curl_cmd 200 curl_es_pod_with_token $espod '/${logging_index}/_count' $test_token | get_count_from_json" \
        "^0\$"
fi
test_message="admin user can access .operations.* indices from es"
os::cmd::expect_success_and_not_text \
    "run_curl_cmd 200 curl_es_pod_with_token $espod '/.operations.*/_count' $test_token | get_count_from_json" \
    "^0\$"

os::log::info now see if regular users have access

test_user_has_proper_access $LOG_NORMAL_USER $LOG_NORMAL_PW access-control-1 access-control-2 -- access-control-3
test_user_has_proper_access $LOG_USER2 $LOG_PW2 access-control-2 access-control-3 -- access-control-1

# create a dummy client cert/key - see if we can impersonate kibana with a cert
certdir=$( mktemp -d )
# if oc has the adm ca command then use it
if oc adm --help | grep -q ' ca .*Manage certificates and keys' ; then
    openshift_admin="oc adm"
elif type -p openshift > /dev/null && openshift --help | grep -q '^  admin ' ; then
    openshift_admin="openshift admin"
else
    openshift_admin="oc adm"
fi
$openshift_admin ca create-signer-cert  \
    --key="${certdir}/ca.key" \
    --cert="${certdir}/ca.crt" \
    --serial="${certdir}/ca.serial.txt" \
    --name="logging-signer-$(date +%Y%m%d%H%M%S)" 2>&1 | artifact_out
cat - ${OS_O_A_L_DIR}/hack/testing/signing.conf > $certdir/signing.conf <<CONF
[ default ]
dir                     = ${certdir}               # Top dir
CONF
touch $certdir/ca.db
openssl req -out "$certdir/test.csr" -new -newkey rsa:2048 -keyout "$certdir/test.key" \
    -subj "/CN=system.logging.kibana/OU=OpenShift/O=Logging" -days 712 -nodes 2>&1 | artifact_out
openssl ca \
    -in "$certdir/test.csr" \
    -notext \
    -out "$certdir/test.crt" \
    -config $certdir/signing.conf \
    -extensions v3_req \
    -batch \
    -extensions server_ext 2>&1 | artifact_out

CURL_ES_CERT=$certdir/test.crt CURL_ES_KEY=$certdir/test.key \
    os::cmd::expect_failure "curl_es $es_svc /.kibana/_count"
CURL_ES_CERT=$certdir/test.crt CURL_ES_KEY=$certdir/test.key \
    os::cmd::expect_failure "curl_es $es_svc /project.*/_count"
CURL_ES_CERT=$certdir/test.crt CURL_ES_KEY=$certdir/test.key \
    os::cmd::expect_failure "curl_es $es_ops_svc /.operations.*/_count"
rm -rf $certdir

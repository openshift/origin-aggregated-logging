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

delete_users=""
REUSE=${REUSE:-false}

function cleanup() {
    local result_code="$?"
    set +e
    if [ "${REUSE:-false}" = false ] ; then
        for user in $delete_users ; do
            oc delete user $user 2>&1 | artifact_out
        done
    fi
    if [ -n "${espod:-}" ] ; then
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
        oc login --username=$user --password=$pw 2>&1 | artifact_out
        delete_users="$delete_users $user"
    fi
    oc login --username=system:admin 2>&1 | artifact_out
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
}

# test the following
# - regular user can access with username/token
#   - directly against es
#   - via kibana pod with kibana cert/key
# - regular user cannot access unavailable indices
#   - directly against es
#   - via kibana pod with kibana cert/key
# - regular user cannot access .operations
#   - via es or kibana
#   - with username admin and no token
#   - with username admin and bogus token
# - username without token fails
#   - via es or kibana
# - token without username fails
#   - via es or kibana
function test_user_has_proper_access() {
    local user=$1; shift
    local pw=$1; shift
    # rest - indices to which access should be granted, followed by --,
    # followed by indices to which access should not be granted
    local expected=1
    local verb=cannot
    local negverb=can
    local nrecs=0
    local kpod=$( get_running_pod kibana )
    eshost=logging-es
    esopshost=logging-es-ops
    if [ "$espod" = "$esopspod" ] ; then
        esopshost=$eshost
    fi
    get_test_user_token $user $pw
    for proj in "$@" ; do
        if [ "$proj" = "--" ] ; then
            expected=0
            verb=can
            negverb=cannot
            continue
        fi
        os::log::info See if user $user $negverb read /project.$proj.*
        nrecs=$( curl_es_pod_with_token $espod "/project.$proj.*/_count" $test_name $test_token | \
                     get_count_from_json )
        if ! os::cmd::expect_success "test $nrecs = $expected" ; then
            os::log::error $user $verb access project.$proj.* indices from es
            curl_es_pod_with_token $espod "/project.$proj.*/_count" $test_name $test_token | python -mjson.tool
            exit 1
        fi
        nrecs=$( curl_es_from_kibana "$kpod" logging-es "/project.$proj.*/_count" $test_name $test_token | \
                     get_count_from_json )
        if ! os::cmd::expect_success "test $nrecs = $expected" ; then
            os::log::error $user $verb access project.$proj.* indices from kibana
            curl_es_from_kibana "$kpod" logging-es "/project.$proj.*/_count" $test_name $test_token | python -mjson.tool
            exit 1
        fi
        # no user name - allow it - look up username corresponding to token
        nrecs=$( curl_es_pod_with_token $espod "/project.$proj.*/_count" "" $test_token | \
                     get_count_from_json )
        if ! os::cmd::expect_success "test $nrecs = $expected" ; then
            os::log::error $user $verb access project.$proj.* indices from es
            curl_es_pod_with_token $espod "/project.$proj.*/_count" "" $test_token | python -mjson.tool
            exit 1
        fi
        nrecs=$( curl_es_from_kibana "$kpod" logging-es "/project.$proj.*/_count" "" $test_token | \
                     get_count_from_json )
        if ! os::cmd::expect_success "test $nrecs = $expected" ; then
            os::log::error $user $verb access project.$proj.* indices from kibana
            curl_es_from_kibana "$kpod" logging-es "/project.$proj.*/_count" "" $test_token | python -mjson.tool
            exit 1
        fi
        # if wrong user name is given, allow it - server will look up and use correct user name, so
        # not possible to specify a privileged username to use for access with an unprivileged token
        nrecs=$( curl_es_pod_with_token $espod "/project.$proj.*/_count" $LOG_ADMIN_USER $test_token | \
                     get_count_from_json )
        if ! os::cmd::expect_success "test $nrecs = $expected" ; then
            os::log::error $user $verb access project.$proj.* indices from es
            curl_es_pod_with_token $espod "/project.$proj.*/_count" $LOG_ADMIN_USER $test_token | python -mjson.tool
            exit 1
        fi
        nrecs=$( curl_es_from_kibana "$kpod" logging-es "/project.$proj.*/_count" $LOG_ADMIN_USER $test_token | \
                     get_count_from_json )
        if ! os::cmd::expect_success "test $nrecs = $expected" ; then
            os::log::error $user $verb access project.$proj.* indices from kibana
            curl_es_from_kibana "$kpod" logging-es "/project.$proj.*/_count" $LOG_ADMIN_USER $test_token | python -mjson.tool
            exit 1
        fi
        if [ "$expected" = 1 ] ; then
            # make sure no access with incorrect auth
            # username with no token
            os::cmd::expect_success_and_text "curl_es_pod_with_token $espod '/project.$proj.*/_count' '$test_name' '' -w '%{response_code}\n'" '^401$'
            os::cmd::expect_success_and_text "curl_es_from_kibana $kpod $eshost '/project.$proj.*/_count' '$test_name' '' -w '%{response_code}\n'" '^401$'
            # username and bogus token
            os::cmd::expect_success_and_text "curl_es_pod_with_token $espod '/project.$proj.*/_count' '$test_name' BOGUS -w '%{response_code}\n'" '^401$'
            os::cmd::expect_success_and_text "curl_es_from_kibana $kpod $eshost '/project.$proj.*/_count' '$test_name' BOGUS -w '%{response_code}\n'" '^401$'
            # no username, no token
            os::cmd::expect_success_and_text "curl_es_pod_with_token $espod '/project.$proj.*/_count' '' '' -w '%{response_code}\n'" '^401$'
            os::cmd::expect_success_and_text "curl_es_from_kibana $kpod $eshost '/project.$proj.*/_count' '' '' -w '%{response_code}\n' -o /dev/null" '^403$'
        fi
    done

    os::log::info See if user $user is denied /.operations.*
    nrecs=$( curl_es_pod_with_token $esopspod "/.operations.*/_count" $test_name $test_token | \
                 get_count_from_json )
    if ! os::cmd::expect_success "test $nrecs = 0" ; then
        os::log::error $LOG_NORMAL_USER has improper access to .operations.* indices from es
        curl_es_pod_with_token $esopspod "/.operations.*/_count" $test_name $test_token | python -mjson.tool
        exit 1
    fi
    esopshost=logging-es-ops
    if [ "$espod" = "$esopspod" ] ; then
        esopshost=logging-es
    fi
    nrecs=$( curl_es_from_kibana "$kpod" "$esopshost" "/.operations.*/_count" $test_name $test_token | \
                 get_count_from_json )
    if ! os::cmd::expect_success "test $nrecs = 0" ; then
        os::log::error $LOG_NORMAL_USER has improper access to .operations.* indices from kibana
        curl_es_pod_with_token $esopspod "/.operations.*/_count" $test_name $test_token | python -mjson.tool
        exit 1
    fi

    os::log::info See if user $user is denied /.operations.* with no token
    os::cmd::expect_success_and_text "curl_es_pod_with_token $esopspod '/.operations.*/_count' $user '' -w '%{response_code}\n'" '^401$'
    os::cmd::expect_success_and_text "curl_es_from_kibana $kpod $esopshost '/.operations.*/_count' $user '' -w '%{response_code}\n'" '^401$'

    os::log::info See if user $user is denied /.operations.* with no username
    os::cmd::expect_success_and_text "curl_es_pod_with_token $esopspod '/.operations.*/_count' '' $test_token -w '%{response_code}\n'" '}403$'
    os::cmd::expect_success_and_text "curl_es_from_kibana $kpod $esopshost '/.operations.*/_count' '' $test_token -w '%{response_code}\n'" '}403$'

    os::log::info See if user $user is denied /.operations.* with no token using $LOG_ADMIN_USER
    os::cmd::expect_success_and_text "curl_es_pod_with_token $esopspod '/.operations.*/_count' $LOG_ADMIN_USER '' -w '%{response_code}\n'" '^401$'
    os::cmd::expect_success_and_text "curl_es_from_kibana $kpod $esopshost '/.operations.*/_count' $LOG_ADMIN_USER '' -w '%{response_code}\n'" '^401$'

    os::log::info See if user $user is denied /.operations.* with a bogus token using $LOG_ADMIN_USER
    os::cmd::expect_success_and_text "curl_es_pod_with_token $esopspod '/.operations.*/_count' $LOG_ADMIN_USER BOGUS -w '%{response_code}\n'" '^401$'
    os::cmd::expect_success_and_text "curl_es_from_kibana $kpod $esopshost '/.operations.*/_count' $LOG_ADMIN_USER BOGUS -w '%{response_code}\n'" '^401$'

    os::log::info See if access is denied to /.operations.* with no username and no token
    os::cmd::expect_success_and_text "curl_es_pod_with_token $esopspod '/.operations.*/_count' '' '' -w '%{response_code}\n'" '^401$'
    os::cmd::expect_success_and_text "curl_es_from_kibana $kpod $esopshost '/.operations.*/_count' '' '' -w '%{response_code}\n' -o /dev/null" '^403$'

    os::log::info See if user $user is denied /.operations.* with username that does not correspond to token
    os::cmd::expect_success_and_text "curl_es_pod_with_token $esopspod '/.operations.*/_count' $LOG_ADMIN_USER $test_token -w '%{response_code}\n'" '}403$'
    os::cmd::expect_success_and_text "curl_es_from_kibana $kpod $esopshost '/.operations.*/_count' $LOG_ADMIN_USER $test_token -w '%{response_code}\n'" '}403$'
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

if oc get users "$LOG_ADMIN_USER" > /dev/null 2>&1 ; then
    echo Using existing admin user $LOG_ADMIN_USER 2>&1 | artifact_out
else
    os::log::info Creating cluster-admin user $LOG_ADMIN_USER
    current_project="$( oc project -q )"
    oc login --username=$LOG_ADMIN_USER --password=$LOG_ADMIN_PW 2>&1 | artifact_out
    oc login --username=system:admin 2>&1 | artifact_out
    oc project $current_project 2>&1 | artifact_out
fi
oc adm policy add-cluster-role-to-user cluster-admin $LOG_ADMIN_USER 2>&1 | artifact_out
os::log::info workaround access_control admin failures - sleep 60 seconds to allow system to process cluster role setting
sleep 60
oc policy can-i '*' '*' --user=$LOG_ADMIN_USER 2>&1 | artifact_out
oc get users 2>&1 | artifact_out

# if you ever want to run this test again on the same machine, you'll need to
# use different usernames, otherwise you'll get this odd error:
# # oc login --username=loguser --password=loguser
# error: The server was unable to respond - verify you have provided the correct host and port and that the server is currently running.
# or - set REUSE=true
LOG_NORMAL_USER=${LOG_NORMAL_USER:-loguserac-$RANDOM}
LOG_NORMAL_PW=${LOG_NORMAL_PW:-loguserac-$RANDOM}

LOG_USER2=${LOG_USER2:-loguser2ac-$RANDOM}
LOG_PW2=${LOG_PW2:-loguser2ac-$RANDOM}

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
get_test_user_token $LOG_ADMIN_USER $LOG_ADMIN_PW
if [ ${LOGGING_NS} = "logging" ] && [ $espod != $esopspod] ; then
  nrecs=$( curl_es_pod_with_token $espod "/${logging_index}/_count" $test_name $test_token | \
           get_count_from_json )
  os::cmd::expect_success "test $nrecs -gt 1"
fi
nrecs=$( curl_es_pod_with_token $esopspod "/.operations.*/_count" $test_name $test_token | \
         get_count_from_json )
os::cmd::expect_success "test $nrecs -gt 1"

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
oc rsync -c elasticsearch $certdir $espod:/tmp 2>&1 | artifact_out
if [ "$espod" != "$esopspod" ] ; then
    oc rsync -c elasticsearch $certdir $esopspod:/tmp 2>&1 | artifact_out
fi

os::cmd::expect_failure "oc exec -c elasticsearch $espod -- \
    curl -s -k --cert $certdir/test.crt --key $certdir/test.key \
    https://localhost:9200/.kibana/_count"
os::cmd::expect_failure "oc exec -c elasticsearch $espod -- \
    curl -s -k --cert $certdir/test.crt --key $certdir/test.key \
    https://localhost:9200/project.*/_count"
os::cmd::expect_failure "oc exec -c elasticsearch $esopspod -- \
    curl -s -k --cert $certdir/test.crt --key $certdir/test.key \
    https://localhost:9200/.operations.*/_count"
rm -rf $certdir

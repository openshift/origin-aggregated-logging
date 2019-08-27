#!/bin/bash

# basic performance test

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

LOGGING_NS=${LOGGING_NS:-openshift-logging}

os::test::junit::declare_suite_start "test/perf-basic"

cleanup() {
    local return_code="$?"
    set +e
    if [ $return_code = 0 ] ; then
        mycmd=os::log::info
    else
        mycmd=os::log::error
    fi
    $mycmd perf-basic test finished at $( date )
    for proj in ${delete_project:-} ; do
        oc delete project $proj --wait=true 2>&1 | artifact_out
        curl_es $es_svc /project.${proj}.* -XDELETE 2>&1 | artifact_out
    done
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

get_load_driver_image() {
    if [ -n "${OPENSHIFT_BUILD_NAMESPACE:-}" -a -n "${IMAGE_FORMAT:-}" ] ; then
        imageprefix=$( echo "$IMAGE_FORMAT" | sed -e 's,/stable:.*$,/,' )
        testimage=${imageprefix}pipeline:src
        testroot=$( pwd )
    elif [ "${USE_IMAGE_STREAM:-false}" = true ] ; then
        # running in a dev env with imagestream builds
        OPENSHIFT_BUILD_NAMESPACE=openshift
        registry=$( oc -n $OPENSHIFT_BUILD_NAMESPACE get is -l logging-infra=development -o jsonpath='{.items[0].status.dockerImageRepository}' | \
            sed 's,/[^/]*$,/,' )
        testimage=${registry}logging-ci-test-runner:latest
        testroot=/go/src/github.com/openshift/origin-aggregated-logging
    else
        # running in a dev env - pushed local builds
        out=$( mktemp )
        oc get is --all-namespaces | grep 'logging-ci-test-runner' > $out
        while read ns name reg_and_name tag rest ; do
            img="${reg_and_name}:${tag}"
            case "$name" in
            *logging-ci-test-runner) testimage="$img" ;;
            esac
        done < $out
        rm -f $out
        testroot=/go/src/github.com/openshift/origin-aggregated-logging
    fi
}

es_svc=$( get_es_svc es )
es_ops_svc=$( get_es_svc es-ops )
es_ops_svc=${es_ops_svc:-$es_svc}

get_load_driver_image
test_template=$OS_O_A_L_DIR/hack/testing/templates/logging-load-driver-template.yaml

# start N test pods in M namespaces
N_PODS=${N_PODS:-1}
N_NAMESPACES=${N_NAMESPACES:-1}
N_RECORDS=${N_RECORDS:-81920}
RECORD_SIZE=${RECORD_SIZE:-1024}
TOTAL_SIZE=$(( N_RECORDS * RECORD_SIZE / ( 1024 * 1024 ) ))
MSGPERSEC=${MSGPERSEC:-1000}

timeout=$(( second * N_RECORDS / MSGPERSEC * 4 ))
delete_project=""
for ii in $( seq 1 $N_NAMESPACES ) ; do
    ns=perfbasic$ii
    if oc get project $ns 2>&1 | artifact_out ; then
        artifact_log use existing project $ns
    else
        os::log::info Creating project $ns
        oc adm new-project $ns --node-selector='' 2>&1 | artifact_out
        os::cmd::try_until_success "oc get project $ns" "${timeout}" 2>&1 | artifact_out
        delete_project="$delete_project $ns"
    fi
done

jj=1
message_uuid=$( openssl rand -hex 16 )
starttime=$( date +%s )
for ii in $( seq 1 $N_PODS ) ; do
    if [ $jj -gt $N_NAMESPACES ] ; then
        jj=1
    fi
    pod=perfbasic$ii
    ns=perfbasic$jj
    oc process -f $test_template \
        -p POD_NAME=$pod \
        -p NAMESPACE=$ns \
        -p IMAGE=$testimage \
        -p LOADER_PATH=$testroot/hack/logging-load-driver/loader \
        -p INVOCID=$message_uuid \
        -p MSGPERSEC=$MSGPERSEC \
        -p PAYLOAD_SIZE=$RECORD_SIZE \
        -p TOTAL_SIZE=$TOTAL_SIZE | oc create -f - 2>&1 | artifact_out
    os::cmd::try_until_text "oc get -n $ns pods $pod" "^${pod}.* Running " "${timeout}"
    jj=$( expr $jj + 1 )
done

jj=1
for ii in $( seq 1 $N_PODS ) ; do
    if [ $jj -gt $N_NAMESPACES ] ; then
        jj=1
    fi
    pod=perfbasic$ii
    ns=perfbasic$jj

    es_rec_count() {
        local cnt=$( curl_es $es_svc /project.$ns.*/_count?q=kubernetes.pod_name:$pod | get_count_from_json ) || :
        test ${cnt:-0} -ge $N_RECORDS
    }
    os::cmd::try_until_success es_rec_count "${timeout}"
done

rc=0
jj=1
for ii in $( seq 1 $N_PODS ) ; do
    if [ $jj -gt $N_NAMESPACES ] ; then
        jj=1
    fi
    pod=perfbasic$ii
    ns=perfbasic$jj
    searchout=$ARTIFACT_DIR/search_out.json
    curl_es_scroll $es_svc /project.$ns.*/_search?q=kubernetes.pod_name:${pod}\&sort=@timestamp:asc\&size=5000 > $searchout
    verifyin=$ARTIFACT_DIR/verify-in.txt
    cat $searchout | jq -r .hits.hits[]._source.message | sort -n > $verifyin
    verifyout=$ARTIFACT_DIR/verify-out.txt
    $OS_O_A_L_DIR/hack/logging-load-driver/verify-loader --report-interval=0 $verifyin > $verifyout 2>&1 || :
    verifyrecs=$( awk '/^+++ verify-loader/ {found=1; next;}; found == 1 {print $2; exit}' $verifyout )
    verifyskips=$( awk '/^+++ verify-loader/ {found=1; next;}; found == 1 {print $3; exit}' $verifyout )
    verifydups=$( awk '/^+++ verify-loader/ {found=1; next;}; found == 1 {print $4; exit}' $verifyout )
    localrc=0
    if [ $verifyrecs -lt $N_RECORDS ] ; then
        rc=1
        localrc=1
        os::log::error Expected $N_RECORDS or more but found $verifyrecs
    fi
    if [ $verifyskips -gt 0 ] ; then
        rc=1
        localrc=1
        os::log::error $verifyskips records were skipped
    fi
    if [ $verifydups -gt 0 ] ; then
        rc=1
        localrc=1
        os::log::error $verifydups records were duplicated
    fi
    if [ $localrc = 0 ] ; then
        os::log::info Success - found $verifyrecs log records - no skips, no duplicates
    fi
done

exit $rc

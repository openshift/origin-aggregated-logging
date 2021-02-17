#!/bin/bash

# This is a test suite for the eventrouter

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"

EXTERNAL_REGISTRY=${EXTERNAL_REGISTRY:-registry.ci.openshift.org}
EXT_REG_IMAGE_NS=${EXT_REG_IMAGE_NS:-origin}
MASTER_VERSION=${MASTER_VERSION:-4.3}
get_eventrouter_image() {
    local tagsuffix="${1:-latest}"
    local ns=openshift
    if [ -n "${IMAGE_FORMAT:-}" ] ; then
        echo ${IMAGE_FORMAT/'${component}'/logging-eventrouter}
    elif oc -n $ns get istag origin-logging-eventrouter:$tagsuffix > /dev/null 2>&1 ; then
        oc -n $ns get istag origin-logging-eventrouter:$tagsuffix -o jsonpath='{.image.dockerImageReference}'
    else
        # fallback to latest externally available image
        echo $EXTERNAL_REGISTRY/$EXT_REG_IMAGE_NS/$MASTER_VERSION:logging-eventrouter
    fi
}

deploy_eventrouter() {
    local image=$( get_eventrouter_image )
    local ns=${LOGGING_NS:-openshift-logging}

    # I want the template to be usable as-is, by any external user, so I
    # don't want to have the nodeSelector in the file - this assumes the
    # deployment is the last element in the template
    oc process -p NAMESPACE=$ns -p IMAGE=$image \
        -f ${OS_O_A_L_DIR}/hack/testing/templates/eventrouter_template.yaml | \
        jq '.items[-1].spec.template.spec.nodeSelector["logging-ci-test"]="true"' | \
        jq '.items[-1].spec.template.spec.containers[0].imagePullPolicy="Always"' | \
        oc create -f - 2>&1 | artifact_out
    local looptries=4
    local ii
    # not sure what's going on here - sometimes eventrouter will get an ErrImagePull
    # due to authentication issue to internal cluster registry - restarting the pod
    # usually makes it work(?????)
    for ii in $(seq 1 $looptries) ; do
        if os::cmd::try_until_text "get_running_pod eventrouter" eventrouter 2>&1 | artifact_out; then
            os::log::info started eventrouter pod $(get_running_pod eventrouter)
            ii=1
            break
        else
            oc delete pod -l component=eventrouter 2>&1 | artifact_out || :
        fi
        sleep 1
    done
    if [ $ii -eq $looptries ] ; then
        os::log::error could not start eventrouter pod after $looptries tries
        exit 1
    fi
}

os::test::junit::declare_suite_start "test/eventrouter"

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 3 * minute ))}

cleanup() {
    local return_code="$?"
    set +e
    if [ $return_code -ne 0 ] ; then
        get_all_logging_pod_logs
        if [ -n "${evpod:-}" ] ; then
            oc logs $evpod > $ARTIFACT_DIR/$evpod.log 2>&1
        fi
    fi
    # remove TRANSFORM_EVENTS
    stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out
    oc set env $fluentd_ds TRANSFORM_EVENTS- 2>&1 | artifact_out
    start_fluentd false $FLUENTD_WAIT_TIME 2>&1 | artifact_out
    oc process -f ${OS_O_A_L_DIR}/hack/testing/templates/eventrouter_template.yaml | \
        oc delete -f - 2>&1 | artifact_out
    os::cmd::try_until_failure "oc get deploy/eventrouter > /dev/null 2>&1"
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

deploy_eventrouter
evpod=$( get_running_pod eventrouter )
if [ -z "$evpod" ]; then
    os::log::warning "Eventrouter not deployed"
    exit 0
fi

function warn_nonformatted() {
    local es_svc=$1
    local index=$2
    # check if eventrouter and fluentd with correct ViaQ plugin are deployed
    local non_formatted_event_count=$( curl_es $es_svc $index/_count?q=verb:* | get_count_from_json )
    if [ "$non_formatted_event_count" != 0 ]; then
        os::log::warning "$non_formatted_event_count events from eventrouter in index $index were not processed by ViaQ fluentd plugin"
    else
        os::log::info "good - looks like all eventrouter events were processed by fluentd"
    fi
}

function logs_count_is_gt() {
    local expected=$1
    local actual=$( curl_es $esopssvc /.operations.*/_count?q=kubernetes.event.verb:* | get_count_from_json )
    test $actual -gt $expected
}

essvc=$( get_es_svc es )
esopssvc=$( get_es_svc es-ops )
esopssvc=${esopssvc:-$essvc}

warn_nonformatted $essvc '/project.*'
warn_nonformatted $esopssvc '/.operations.*'

os::cmd::try_until_not_text "curl_es $esopssvc /.operations.*/_count?q=kubernetes.event.verb:* | get_count_from_json" "^0\$" $FLUENTD_WAIT_TIME
prev_event_count=$( curl_es $esopssvc /.operations.*/_count?q=kubernetes.event.verb:* | get_count_from_json )

# Check if 1) the doc _id is the same as the kube id 2) there's no duplicates
curl_es $esopssvc /.operations.*/_search?pretty\&q=kubernetes.event:*\&size=9999 > $ARTIFACT_DIR/id-dup-search-raw.json 2>&1
cat $ARTIFACT_DIR/id-dup-search-raw.json | jq -r '.hits.hits[] | ._id + " " + ._source.kubernetes.event.metadata.uid' | sort > $ARTIFACT_DIR/id-and-uid
os::cmd::expect_success "test -s $ARTIFACT_DIR/id-and-uid"
cat $ARTIFACT_DIR/id-and-uid | awk '{
    if ($1 != $2) {print "Error: es _id " $1 " not equal to kube uid " $2; exit 1}
    if ($1 == last1) {print "Error: found duplicate es _id " $1; exit 1}
    if ($2 == last2) {print "Error: found duplicate kube uid " $2; exit 1}
    last1 = $1; last2 = $2
}'

oc apply -f - <<EOF
{
    "apiVersion": "v1",
    "count": 1,
    "eventTime": null,
    "involvedObject": {
        "apiVersion": "apps.openshift.io/v1",
        "kind": "DeploymentConfig",
        "name": "eventroutertest",
        "namespace": "default"
    },
    "kind": "Event",
    "message": "eventroutertest",
    "metadata": {
        "name": "eventroutertest",
        "namespace": "default"
    },
    "reason": "DeploymentCreated",
    "reportingComponent": "",
    "reportingInstance": "",
    "source": {
        "component": "deploymentconfig-controller"
    },
    "type": "Info"
}
EOF

if ! os::cmd::try_until_text "curl_es $esopssvc /.operations.*/_count?q=kubernetes.event.metadata.name:eventroutertest | get_count_from_json" "^1\$" $FLUENTD_WAIT_TIME ; then
    os::log::error did not find 1 record with type Info
    curl_es $esopssvc /.operations.*/_search?q=kubernetes.event.metadata.name:eventroutertest\&pretty > $ARTIFACT_DIR/info-search.json 2>&1 || :
    exit 1
fi

# disable eventrouter mode
stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out
oc set env $fluentd_ds TRANSFORM_EVENTS=false 2>&1 | artifact_out
start_fluentd false $FLUENTD_WAIT_TIME 2>&1 | artifact_out

oc apply -f - <<EOF
{
    "apiVersion": "v1",
    "count": 1,
    "eventTime": null,
    "involvedObject": {
        "apiVersion": "apps.openshift.io/v1",
        "kind": "DeploymentConfig",
        "name": "2eventroutertest2",
        "namespace": "default"
    },
    "kind": "Event",
    "message": "2eventroutertest2",
    "metadata": {
        "name": "2eventroutertest2",
        "namespace": "default"
    },
    "reason": "DeploymentCreated",
    "reportingComponent": "",
    "reportingInstance": "",
    "source": {
        "component": "deploymentconfig-controller"
    },
    "type": "Info"
}
EOF

if ! os::cmd::try_until_text "curl_es $esopssvc /.operations.*/_count?q=event.metadata.name:2eventroutertest2 | get_count_from_json" "^1\$" $FLUENTD_WAIT_TIME ; then
    os::log::error the event 2eventroutertest2 was processed as a kubernetes event even though TRANSFORM_EVENTS=false
    curl_es $esopssvc /.operations.*/_search?q=event.metadata.name:2eventroutertest2\&pretty > $ARTIFACT_DIR/info-search-2.json 2>&1 || :
    curl_es $esopssvc /.operations.*/_search?q=kubernetes.event.metadata.name:2eventroutertest2\&pretty > $ARTIFACT_DIR/info-search-3.json 2>&1 || :
    exit 1
fi

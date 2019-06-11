#!/bin/bash
# this is meant to be sourced - called in the current context
# of the script as TEST_COMMAND - rather than called as a separate
# fork/exec script so that variables such as OPENSHIFT_BUILD_NAMESPACE and
# ARTIFACT_DIR will be available - see
# https://github.com/openshift/release/blob/master/ci-operator/templates/cluster-launch-installer-src.yaml
# where the script will sourced

set -eux

logging_err_exit() {
    oc get deploy -o yaml >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc get pods -o wide >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc -n $ESO_NS get elasticsearch -o yaml >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc get clusterlogging -o yaml >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc get crds >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc describe pods >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    for p in $( oc get pods -o jsonpath='{.items[*].metadata.name}' ) ; do
        for container in $( oc get po $p -o jsonpath='{.spec.containers[*].name}' ) ; do
            echo pod $p container $container >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
            oc logs -c $container $p >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
            oc exec -c $container $p -- logs >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
        done
    done
    oc get events >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc get nodes >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    cat ${ARTIFACT_DIR}/test_output
    exit 1
}

wait_for_condition()
{
    # $1 is shell function condition to execute until it returns success
    # $2 is the timeout number of retries - default 60
    # $3 is the interval in seconds - default 1
    # e.g. the total timeout in seconds is timeout * interval
    local cmd=$1
    local timeout=${2:-60}
    local interval=${3:-1}
    local ii=0
    for ii in $( seq 1 $timeout ) ; do
        if $cmd ; then
            break
        fi
        sleep $interval
    done
    if [ $ii = $timeout ] ; then
        return 1
    fi
    return 0
}

ARTIFACT_DIR=${ARTIFACT_DIR:-"$( pwd )/_output"}
if [ ! -d $ARTIFACT_DIR ] ; then
    mkdir -p $ARTIFACT_DIR
fi
DEFAULT_TIMEOUT=${DEFAULT_TIMEOUT:-600}
ESO_NS=${ESO_NS:-openshift-operators-redhat}
esopod=$( oc -n $ESO_NS get pods | awk '/^elasticsearch-operator-.* Running / {print $1}' )
if [ -z "$esopod" ] ; then
    ESO_NS=openshift-logging
    esopod=$( oc -n $ESO_NS get pods | awk '/^elasticsearch-operator-.* Running / {print $1}' )
fi
if [ -z "$esopod" ] ; then
    echo ERROR: could not find elasticsearch-operator running in openshift-operators-redhat or openshift-logging
    logging_err_exit
fi

# set elasticsearch to unmanaged - so that the elasticsearch-operator
# won't try to do anything to elasticsearch when we shut it down
oc patch elasticsearch elasticsearch --type=json --patch '[
        {"op":"replace","path":"/spec/managementState","value":"Unmanaged"}]'

# get the elasticsearch-operator pod
esopod=$( oc -n $ESO_NS get pods | awk '/^elasticsearch-operator-.* Running / {print $1}' )

# disable the elasticsearch-operator so that we can alter elasticsearch
oc -n $ESO_NS scale --replicas=0 deploy/elasticsearch-operator

wait_func() {
    oc -n $ESO_NS get pod $esopod > /dev/null 2>&1
}
if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: could not stop elasticsearch-operator pod $esopod
    logging_err_exit
fi

# sometimes elasticsearch gets stuck in a strange state - the pod is
# running but the deployment status says paused - so kick it here
for dp in $( oc get deploy -l component=elasticsearch -o name ) ; do
    if oc get $dp -o yaml | grep -q "reason: DeploymentPaused" ; then
        oc rollout resume $dp
    fi
    # wait for oc rollout status to return success
    wait_func() {
        oc rollout status --watch=false $dp | grep -q "successfully rolled out"
    }
    if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
        echo ERROR: elasticsearch deployment $dp not reporting success
        logging_err_exit
    fi
done

# the ci test pod, kibana pod, and fluentd/rsyslog pod, all have to run on the same node
kibnode=$( oc get pods -l component=kibana -o jsonpath='{.items[0].spec.nodeName}' )
oc label node $kibnode --overwrite logging-ci-test=true

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
# create secret for test and add $KUBECONFIG contents
oc create secret generic logging-ci-test-kubeconfig \
    --from-file=admin.kubeconfig.orig=$KUBECONFIG
# we're using the same image as what we are currently running in, just launching
# it in a pod in the remote cluster - so the pwd is the test root is the same
# there and here
if [ -n "${ARTIFACT_DIR:-}" ] ; then
    artifact_dir_arg="-p ARTIFACT_DIR=$ARTIFACT_DIR"
fi
if [ -n "${TEST_SUITES:-}" ] ; then
    test_suites_arg="-p TEST_SUITES=${TEST_SUITES}"
fi
oc process -p TEST_ROOT=$testroot \
    -p TEST_NAMESPACE_NAME=$( oc project -q ) \
    -p TEST_IMAGE=$testimage \
    ${artifact_dir_arg:-} ${test_suites_arg:-} \
    -f hack/testing/templates/logging-ci-test-runner-template.yaml | oc create -f -

# wait until logging-ci-test-runner is running on the kibana node
wait_func() {
    oc logs logging-ci-test-runner > /dev/null 2>&1
    local lnode=$( oc get pods logging-ci-test-runner -o jsonpath='{.spec.nodeName}' )
    local knode=$( oc get pods -l component=kibana -o jsonpath='{.items[0].spec.nodeName}' )
    test "${lnode:-l}" = "${knode:-k}"
}
if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: failed to start logging-ci-test-runner after $DEFAULT_TIMEOUT seconds
    logging_err_exit
fi

# this will exit with error when the pod exits - ignore that error
get_test_logs() {
    set +o pipefail
    echo begin tailing logs at $( date --rfc-3339=sec )
    oc exec logging-ci-test-runner -- tail -F $ARTIFACT_DIR/logging-test-output 2>&1 | tee $ARTIFACT_DIR/logging-test-output || :
    echo stop tailing logs at $( date --rfc-3339=sec )
    set -o pipefail
}
get_test_logs &
# wait for the file $ARTIFACT_DIR/logging-test-result to exist - the contents
# will be PASS or FAIL
timeout=240
# 240 * 30 seconds = 7200 seconds = 2 hours
wait_func() {
    result=$( oc exec logging-ci-test-runner -- cat $ARTIFACT_DIR/logging-test-result 2> /dev/null ) && [ -n "$result" ]
}
if ! wait_for_condition wait_func $timeout 30 > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: logging tests did not complete after $(( timeout * 30 )) seconds
    logging_err_exit
fi
result=$( oc exec logging-ci-test-runner -- cat $ARTIFACT_DIR/logging-test-result 2> /dev/null )

# copy the artifacts out of the test runner pod
oc version
echo starting artifact rsync at $( date --rfc-3339=sec )
if ! oc --loglevel=3 rsync --strategy=rsync logging-ci-test-runner:$ARTIFACT_DIR/ $ARTIFACT_DIR > ${ARTIFACT_DIR}/syncout 2>&1 ; then
    echo ERROR: failure in oc rsync --strategy=rsync logging-ci-test-runner:$ARTIFACT_DIR/ $ARTIFACT_DIR
    echo see ${ARTIFACT_DIR}/syncout for details
fi
echo finished artifact rsync at $( date --rfc-3339=sec )

# tell the logging test pod we are done copying artifacts
if oc exec logging-ci-test-runner -- touch $ARTIFACT_DIR/artifacts-done ; then
    echo notified logging-ci-test-runner - done with artifacts
else
    echo error notifying logging-ci-test-runner - $? - ignoring
fi

wait || :
oc delete --force pod logging-ci-test-runner || :
echo finished $0 at $( date --rfc-3339=sec )
if [ "$result" = PASS ] ; then
    exit 0
else
    exit 1
fi

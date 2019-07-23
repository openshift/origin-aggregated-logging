#!/bin/bash
# this is meant to be sourced - called in the current context
# of the script as TEST_COMMAND - rather than called as a separate
# fork/exec script so that variables such as OPENSHIFT_BUILD_NAMESPACE and
# ARTIFACT_DIR will be available - see
# https://github.com/openshift/release/blob/master/ci-operator/templates/cluster-launch-installer-src.yaml
# where the script will sourced

set -eux

logging_err_exit() {
    oc get deploy >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc get pods >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc -n $ESO_NS get elasticsearch >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc get clusterlogging >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc get crds >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc describe pods >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    for p in $( oc get pods -o jsonpath='{.items[*].metadata.name}' ) ; do
        for container in $( oc get po $p -o jsonpath='{.spec.containers[*].name}' ) ; do
            echo pod $p container $container >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
            oc logs -c $container $p >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
        done
    done
    oc get events >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
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

switch_to_admin_user() {
    # make sure we are using the admin credentials for the remote repo
    if [ -z "${KUBECONFIG:-}" ] ; then
        echo WARNING: KUBECONFIG is not set - assuming you have set credentials
        echo via ~/.kube/config or otherwise
    fi

    if ! oc auth can-i view pods/log -n default > /dev/null 2>&1 ; then
        local adminname
        local oldcontext=$( oc config current-context )
        # see if there is already an admin context in the kubeconfig
        for adminname in admin system:admin kube:admin ; do
            if oc config use-context $adminname > /dev/null 2>&1 ; then
                break
            fi
        done
        if oc auth can-i view pods/log -n default > /dev/null 2>&1 ; then
            echo INFO: switched from context [$oldcontext] to [$(oc config current-context)]
        else
            echo ERROR: could not get an admin context to use - make sure you have
            echo set KUBECONFIG or ~/.kube/config correctly
            oc config use-context $oldcontext
            exit 1
        fi
    fi
}

switch_to_admin_user

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

echo before patching kibana
oc get pods -o wide

# the ci test pod, kibana pod, and fluentd/rsyslog pod, all have to run on the same node
kibnode=$( oc get pods -l component=kibana -o jsonpath='{.items[0].spec.nodeName}' )
oc label node $kibnode --overwrite logging-ci-test=true

# make sure nodeSelectors are set correctly if restarted later by CLO
oc patch clusterlogging instance --type=json --patch '[
    {"op":"add","path":"/spec/collection/logs/fluentd/nodeSelector","value":{"logging-ci-test":"true"}},
    {"op":"add","path":"/spec/collection/logs/rsyslog/nodeSelector","value":{"logging-ci-test":"true"}},
    {"op":"add","path":"/spec/visualization/kibana/nodeSelector","value":{"logging-ci-test":"true"}}]'

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

wait_func() {
    oc logs logging-ci-test-runner > /dev/null 2>&1
}
if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: failed to start logging-ci-test-runner after $DEFAULT_TIMEOUT seconds
    logging_err_exit
fi

echo after starting logging-ci-test-runner
oc get pods -o wide

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

#!/bin/bash
# this is meant to be sourced from CI - called in the current context
# of the script as TEST_COMMAND - rather than called as a separate
# fork/exec script so that variables such as OPENSHIFT_BUILD_NAMESPACE and
# ARTIFACT_DIR will be available - see
# https://github.com/openshift/release/blob/master/ci-operator/templates/cluster-launch-installer-src.yaml
# where the script will sourced
# It can also be called directly as a regular shell script

# This script will deploy logging using the marketplace/subscription method
# It will use custom images if it detects it is being used in the CI or
# dev environment - you can override this with USE_CUSTOM_IMAGES=false
# It will deploy logging using the CI cr.yaml - if you want to use
# another CR, specify the file in CLUSTERLOGGING_CR_FILE

# If you are using a publicly released version and want to use the released
# images, then set USE_CUSTOM_IMAGES=false and USE_OLM=true

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

deploy_logging_using_olm() {
    # Create the $ESO_NS namespace:
    if oc get project $ESO_NS > /dev/null 2>&1 ; then
        echo using existing project $ESO_NS
    else
        oc create -f $TEST_OBJ_DIR/openshift-operators-redhat-namespace.yaml
    fi
    oc get projects | grep logging || :

    # Create an OperatorGroup for $LOGGING_NS:
    oc -n ${LOGGING_NS} create -f $TEST_OBJ_DIR/openshift-logging-operatorgroup.yaml
    # Create an OperatorGroup for $ESO_NS:
    oc -n $ESO_NS create -f $TEST_OBJ_DIR/openshift-operators-redhat-operatorgroup.yaml

    # Create the CatalogSourceConfig for the elasticsearch-operator in the namespace openshift-marketplace:
    oc create -n openshift-marketplace -f $TEST_OBJ_DIR/elasticsearch-catalogsourceconfig.yaml
    oc get -n openshift-marketplace CatalogSourceConfig | grep elasticsearch || :

    # Create the subscription for elasticsearch in the namespace $ESO_NS:
    oc create -n $ESO_NS -f $TEST_OBJ_DIR/elasticsearch-subscription.yaml
    oc get -n $ESO_NS subscriptions | grep elasticsearch || :

    # Create the CatalogSourceConfig for cluster-logging in the namespace openshift-marketplace:
    oc create -n openshift-marketplace -f $TEST_OBJ_DIR/cluster-logging-catalogsourceconfig.yaml
    oc get -n openshift-marketplace CatalogSourceConfig | grep logging || :

    # create the subscription in the namespace $LOGGING_NS:
    oc create -n ${LOGGING_NS} -f $TEST_OBJ_DIR/cluster-logging-subscription.yaml
    oc get -n ${LOGGING_NS} subscriptions | grep logging || :
}

deploy_logging_using_clo_make() {
    if [ ! -d $GOPATH/src/github.com/openshift/elasticsearch-operator ] ; then
        git clone https://github.com/${EO_REPO:-openshift}/elasticsearch-operator \
            $GOPATH/src/github.com/openshift/elasticsearch-operator -b ${EO_BRANCH:-master}
    fi
    if [ ! -d $GOPATH/src/github.com/openshift/cluster-logging-operator ] ; then
        git clone https://github.com/${CLO_REPO:-openshift}/cluster-logging-operator \
            $GOPATH/src/github.com/openshift/cluster-logging-operator -b ${CLO_BRANCH:-master}
    fi
    # edit the deployment manifest - use the images provided by CI or from api.ci registry
    # make deploy-no-build
    # during CI, the env var IMAGE_FORMAT is present:
    # IMAGE_FORMAT=registry.svc.ci.openshift.org/ci-op-xxx/stable:${component}
    # the EO image is registry.svc.ci.openshift.org/ci-op-xxx/stable:elasticsearch-operator
    # the CLO image is registry.svc.ci.openshift.org/ci-op-xxx/stable:cluster-logging-operator
    if [ -n "${IMAGE_FORMAT:-}" ] ; then
        EO_IMAGE=$( echo "$IMAGE_FORMAT" | sed 's/\${component}/elasticsearch-operator/' )
        CLO_IMAGE=$( echo "$IMAGE_FORMAT" | sed 's/\${component}/cluster-logging-operator/' )
    else
        EO_IMAGE=$EXTERNAL_REGISTRY/$EXT_REG_IMAGE_NS/$MASTER_VERSION:elasticsearch-operator
        CLO_IMAGE=$EXTERNAL_REGISTRY/$EXT_REG_IMAGE_NS/$MASTER_VERSION:cluster-logging-operator
    fi

    pushd $GOPATH/src/github.com/openshift/cluster-logging-operator > /dev/null
    REMOTE_CLUSTER=true REMOTE_REGISTRY=true NAMESPACE=openshift-logging \
        IMAGE_OVERRIDE="$CLO_IMAGE" EO_IMAGE_OVERRIDE="$EO_IMAGE" make deploy-no-build
    popd > /dev/null
}

# what numeric version does master correspond to?
MASTER_VERSION=${MASTER_VERSION:-4.2}
# what namespace to use for operator images?
EXTERNAL_REGISTRY=${EXTERNAL_REGISTRY:-registry.svc.ci.openshift.org}
EXT_REG_IMAGE_NS=${EXT_REG_IMAGE_NS:-origin}
USE_OLM=${USE_OLM:-false}

if [ -z "${USE_CUSTOM_IMAGES:-}" ] ; then
    if [ -n "${OPENSHIFT_BUILD_NAMESPACE:-}" -a -n "${IMAGE_FORMAT:-}" ] ; then
        USE_CUSTOM_IMAGES=true
    elif [ "${USE_IMAGE_STREAM:-false}" = true ] ; then
        USE_CUSTOM_IMAGES=true
    elif [ "${USE_CLO_LATEST_IMAGE:-false}" = true -o "${USE_EO_LATEST_IMAGE:-false}" = true ] ; then
        USE_CUSTOM_IMAGES=true
    else
        # default to false
        USE_CUSTOM_IMAGES=false
    fi
fi
LOGGING_NS=${LOGGING_NS:-openshift-logging}
ESO_NS=${ESO_NS:-openshift-operators-redhat}
TEST_OBJ_DIR=${TEST_OBJ_DIR:-openshift/ci-operator/build-image}
ARTIFACT_DIR=${ARTIFACT_DIR:-"$( pwd )/_output"}
if [ ! -d $ARTIFACT_DIR ] ; then
    mkdir -p $ARTIFACT_DIR
fi

# Create the $LOGGING_NS namespace:
if oc get project $LOGGING_NS > /dev/null 2>&1 ; then
    echo using existing project $LOGGING_NS
else
    oc create -f $TEST_OBJ_DIR/openshift-logging-namespace.yaml
fi

if [ "${USE_OLM:-false}" = true ] ; then
    deploy_logging_using_olm
else
    ESO_NS=openshift-logging
    deploy_logging_using_clo_make
fi

# at this point, the cluster-logging-operator should be deployed in the
# $LOGGING_NS namespace
oc project ${LOGGING_NS}

DEFAULT_TIMEOUT=${DEFAULT_TIMEOUT:-600}
wait_func() {
    oc -n $ESO_NS get pods 2> /dev/null | grep -q 'elasticsearch-operator.*Running' && \
    oc get pods 2> /dev/null | grep -q 'cluster-logging-operator.*Running'
}
if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: one of or both of elasticsearch-operator and cluster-logging-operator pod not running
    logging_err_exit
fi

if [ "$USE_CUSTOM_IMAGES" = true ] ; then
    if [ "${USE_OLM:-false}" = true ] ; then
        # get the OLM pod
        olmpod=$( oc -n openshift-operator-lifecycle-manager get pods | awk '/^olm-operator-.* Running / {print $1}' )
        # disable the OLM so that we can change images in the cluster-logging-operator
        oc -n openshift-operator-lifecycle-manager scale --replicas=0 deploy/olm-operator
        wait_func() {
            oc -n openshift-operator-lifecycle-manager get pod $olmpod > /dev/null 2>&1
        }
        if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
            echo ERROR: could not stop olm pod $olmpod
            logging_err_exit
        fi
    fi

    clopod=$( oc get pods | awk '/^cluster-logging-operator-.* Running / {print $1}' )
    eopod=$( oc -n $ESO_NS get pods | awk '/^elasticsearch-operator-.* Running / {print $1}' )

    # update the images to use in the CLO
    if [ -n "${OPENSHIFT_BUILD_NAMESPACE:-}" -a -n "${IMAGE_FORMAT:-}" ] ; then
        # we are running in the CI environment
        # OPENSHIFT_BUILD_NAMESPACE=ci-op-xxx
        # IMAGE_FORMAT=registry.svc.ci.openshift.org/ci-op-xxx/stable:${component}
        # edit the deployments - for the logging images, use pipeline
        # for example, change this:
        # docker.io/openshift/origin-logging-elasticsearch5:latest
        # to this:
        # $imageprefix/pipeline:logging-elasticsearch5
        imageprefix=$( echo "$IMAGE_FORMAT" | sed -e 's,/stable:.*$,/,' )
        oc set env deploy/cluster-logging-operator --list | grep _IMAGE= | \
        sed -e 's,docker.io/openshift/origin-logging-\(..*\):latest,'"$imageprefix"'pipeline:logging-\1,' \
            -e 's,quay.io/openshift/origin-logging-\(..*\):latest,'"$imageprefix"'pipeline:logging-\1,' | \
        oc set env -e - deploy/cluster-logging-operator
        # special handling for rsyslog for now
        oc set env deploy/cluster-logging-operator RSYSLOG_IMAGE=${imageprefix}pipeline:logging-rsyslog
    elif [ "${USE_IMAGE_STREAM:-false}" = true ] ; then
        # running in a dev env with imagestream builds
        OPENSHIFT_BUILD_NAMESPACE=openshift
        registry=$( oc -n $OPENSHIFT_BUILD_NAMESPACE get is -l logging-infra=development -o jsonpath='{.items[0].status.dockerImageRepository}' | \
            sed 's,/[^/]*$,/,' )
        oc set env deploy/cluster-logging-operator --list | grep _IMAGE= | \
        sed -e '/docker.io\/openshift\/origin-logging-/ {s,docker.io/openshift/origin-,'"$registry"',}' \
            -e '/quay.io\/openshift\/origin-logging-/ {s,quay.io/openshift/origin-,'"$registry"',}' | \
        oc set env -e - deploy/cluster-logging-operator
        # special handling for rsyslog for now
        oc set env deploy/cluster-logging-operator RSYSLOG_IMAGE=${registry}logging-rsyslog:latest
    else
        # running in a dev env - pushed local builds
        out=$( mktemp )
        oc get is --all-namespaces | grep -E 'logging-|elasticsearch-operator' > $out || :
        found=""
        while read ns name reg_and_name tag rest ; do
            img="${reg_and_name}:${tag}"
            case "$name" in
            *-cluster-logging-operator) cloimg="$img" ; found="$found cluster-logging-operator" ;;
            *-elasticsearch-operator) eoimg="$img" ; found="$found elasticsearch-operator" ;;
            *-elasticsearch*) oc set env deploy/cluster-logging-operator ELASTICSEARCH_IMAGE="$img"
                              found="$found elasticsearch5" ;;
            *-kibana*) oc set env deploy/cluster-logging-operator KIBANA_IMAGE="$img"
                       found="$found kibana5" ;;
            *-curator*) oc set env deploy/cluster-logging-operator CURATOR_IMAGE="$img"
                        found="$found curator5" ;;
            *-fluentd) oc set env deploy/cluster-logging-operator FLUENTD_IMAGE="$img"
                       found="$found fluentd" ;;
            *-rsyslog) oc set env deploy/cluster-logging-operator RSYSLOG_IMAGE="$img"
                       found="$found rsyslog" ;;
            esac
        done < $out
        rm -f $out
        for comp_and_name in curator5:CURATOR_IMAGE elasticsearch5:ELASTICSEARCH_IMAGE fluentd:FLUENTD_IMAGE \
            kibana5:KIBANA_IMAGE rsyslog:RSYSLOG_IMAGE ; do
            comp=$( echo $comp_and_name | awk -F: '{print $1}' )
            envname=$( echo $comp_and_name | awk -F: '{print $2}' )
            for ff in $found ; do
                if [ $ff = $comp ] ; then
                    comp=""
                    break
                fi
            done
            if [ -n "$comp" ] ; then
                img=$EXTERNAL_REGISTRY/$EXT_REG_IMAGE_NS/$MASTER_VERSION:logging-$comp
                oc set env deploy/cluster-logging-operator ${envname}="$img"
            fi
        done
        if [ "${USE_CLO_LATEST_IMAGE:-false}" = true -a -n "${cloimg:-}" ] ; then
            oc patch deploy/cluster-logging-operator --type=json \
                --patch '[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"'"$cloimg"'"}]'
        fi
        if [ "${USE_EO_LATEST_IMAGE:-false}" = true -a -n "${eoimg:-}" ] ; then
            oc -n $ESO_NS patch deploy/elasticsearch-operator --type=json \
                --patch '[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"'"$eoimg"'"}]'
            # doing the oc patch will restart eo - check to make sure it was restarted
            wait_func() {
                # wait until the old eo pod is not running and a new one is
                ! oc -n $ESO_NS get pods $eopod > /dev/null 2>&1 && \
                oc -n $ESO_NS get pods | grep -q '^elasticsearch-operator-.* Running'
            }
            if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
                echo ERROR: elasticsearch-operator pod was not restarted
                logging_err_exit
            fi
        fi
    fi

    # doing the oc set env and patch will restart clo - check to make sure it was restarted
    wait_func() {
        # wait until the old clo pod is not running and a new one is
        ! oc get pods $clopod > /dev/null 2>&1 && oc get pods | grep -q '^cluster-logging-operator-.* Running'
    }
    if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
        echo ERROR: cluster-logging-operator pod was not restarted
        logging_err_exit
    fi

    oc set env deploy/cluster-logging-operator --list | grep _IMAGE=
fi

oc -n $LOGGING_NS create -f ${CLUSTERLOGGING_CR_FILE:-$TEST_OBJ_DIR/cr.yaml}

# we expect a fluentd or rsyslog running on each node
expectedcollectors=$( oc get nodes | grep -c " Ready " )
if grep -q 'type:.*rsyslog' ${CLUSTERLOGGING_CR_FILE:-$TEST_OBJ_DIR/cr.yaml} ; then
    collector=rsyslog
else
    collector=fluentd
fi
# we expect $nodeCount elasticsearch pods
expectedes=$( awk '/nodeCount:/ {print $2}' ${CLUSTERLOGGING_CR_FILE:-$TEST_OBJ_DIR/cr.yaml} )

wait_func() {
    if ! oc get pods -l component=kibana 2> /dev/null | grep -q 'kibana.*Running' ; then
        return 1
    fi
    local actualcollectors=$( oc get pods -l component=$collector 2> /dev/null | grep -c "${collector}.*Running" )
    if [ $expectedcollectors -ne ${actualcollectors:-0} ] ; then
        return 1
    fi
    local actuales=$( oc get pods -l component=elasticsearch 2> /dev/null | grep -c 'elasticsearch.* 2/2 .*Running' )
    if [ $expectedes -ne ${actuales:-0} ] ; then
        return 1
    fi
    # if we got here, everything is as it should be
    return 0
}
if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: operator did not start pods after 300 seconds
    logging_err_exit
fi

echo Logging successfully deployed

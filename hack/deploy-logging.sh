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

# what numeric version does master correspond to?
MASTER_VERSION=${MASTER_VERSION:-4.2}
# what namespace to use for operator images?
EXTERNAL_REGISTRY=${EXTERNAL_REGISTRY:-registry.svc.ci.openshift.org}
EXT_REG_IMAGE_NS=${EXT_REG_IMAGE_NS:-origin}
# for dev purposes, image builds will typically be pushed to this namespace
OPENSHIFT_BUILD_NAMESPACE=${OPENSHIFT_BUILD_NAMESPACE:-openshift}

construct_image_name() {
    local component="$1"
    local tagsuffix="${2:-latest}"
    # if running in CI environment, IMAGE_FORMAT will look like this:
    # IMAGE_FORMAT=registry.svc.ci.openshift.org/ci-op-xxx/stable:${component}
    # stable is the imagestream containing the images built for this PR, or
    # otherwise the most recent image
    if [ -n "${IMAGE_FORMAT:-}" ] ; then
        if [ -n "${LOGGING_IMAGE_STREAM:-}" ] ; then
            local match=/stable:
            local replace="/${LOGGING_IMAGE_STREAM}:"
            IMAGE_FORMAT=${IMAGE_FORMAT/$match/$replace}
        fi
        echo ${IMAGE_FORMAT/'${component}'/$component}
    elif oc -n ${OPENSHIFT_BUILD_NAMESPACE} get istag origin-${component}:$tagsuffix > /dev/null 2>&1 ; then
        oc -n ${OPENSHIFT_BUILD_NAMESPACE} get istag origin-${component}:$tagsuffix -o jsonpath='{.image.dockerImageReference}'
    else
        # fallback to latest externally available image
        echo $EXTERNAL_REGISTRY/$EXT_REG_IMAGE_NS/$MASTER_VERSION:$component
    fi
}

wait_for_logging_is_running() {
    # we expect a fluentd or rsyslog running on each node
    expectedcollectors=$( oc get nodes | grep -c " Ready " )
    if [ "${LOGGING_DEPLOY_MODE:-install}" = install ] ; then
        if grep -q 'type:.*rsyslog' ${CLUSTERLOGGING_CR_FILE:-$TEST_OBJ_DIR/cr.yaml} ; then
            collector=rsyslog
        else
            collector=fluentd
        fi
    else
        collector=$( oc get clusterlogging instance -o jsonpath='{.spec.collection.logs.type}' )
    fi
    # we expect $nodeCount elasticsearch pods
    wait_func() {
        if ! oc get pods -l component=kibana 2> /dev/null | grep -q 'kibana.* 2/2 .*Running' ; then
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
    EO_IMAGE=$( construct_image_name elasticsearch-operator latest )
    CLO_IMAGE=$( construct_image_name cluster-logging-operator latest )
    pushd $GOPATH/src/github.com/openshift/cluster-logging-operator > /dev/null
    REMOTE_CLUSTER=true REMOTE_REGISTRY=true NAMESPACE=openshift-logging \
        IMAGE_OVERRIDE="$CLO_IMAGE" EO_IMAGE_OVERRIDE="$EO_IMAGE" make deploy-no-build
    popd > /dev/null
}

DEFAULT_TIMEOUT=${DEFAULT_TIMEOUT:-600}

switch_to_admin_user

USE_OLM=${USE_OLM:-false}

if [ -z "${USE_CUSTOM_IMAGES:-}" ] ; then
    if [ -n "${OPENSHIFT_BUILD_NAMESPACE:-}" -a -n "${IMAGE_FORMAT:-}" ] ; then
        USE_CUSTOM_IMAGES=true
    elif [ "${USE_IMAGE_STREAM:-false}" = true ] ; then
        USE_CUSTOM_IMAGES=true
    elif [ "${USE_CLO_LATEST_IMAGE:-false}" = true -o "${USE_EO_LATEST_IMAGE:-false}" = true ] ; then
        USE_CUSTOM_IMAGES=true
    else
        # default to false - false means "use whatever images are defined in the default deployment"
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

if [ "${LOGGING_DEPLOY_MODE:-install}" = install ] ; then
    expectedes=$( awk '/nodeCount:/ {print $2}' ${CLUSTERLOGGING_CR_FILE:-$TEST_OBJ_DIR/cr.yaml} )
else
    expectedes=$( oc get clusterlogging instance -o jsonpath='{.spec.logStore.elasticsearch.nodeCount}' )
fi

if [ "${LOGGING_DEPLOY_MODE:-install}" = install ] ; then
    if [ "${USE_OLM:-false}" = true ] ; then
        deploy_logging_using_olm
    else
        ESO_NS=openshift-logging
        deploy_logging_using_clo_make
    fi
else
    # expect everything is already running
    wait_for_logging_is_running
    # dump current images
    oc get deploy,ds,cronjob -o yaml | awk '/ image: / {print $2}' > $ARTIFACT_DIR/pre-upgrade-images
    # if elasticsearch-operator is running in $LOGGING_NS, then set ESO_NS=$LOGGING_NS
    if oc -n $LOGGING_NS get deploy/elasticsearch-operator -o name > /dev/null 2>&1 ; then
        ESO_NS=$LOGGING_NS
    fi
fi

# at this point, the cluster-logging-operator should be deployed in the
# $LOGGING_NS namespace
oc project ${LOGGING_NS}

if [ "${LOGGING_DEPLOY_MODE:-install}" = install ] ; then
    wait_func() {
        oc -n $ESO_NS get pods 2> /dev/null | grep -q 'elasticsearch-operator.*Running' && \
        oc get pods 2> /dev/null | grep -q 'cluster-logging-operator.*Running'
    }
    if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
        echo ERROR: one of or both of elasticsearch-operator and cluster-logging-operator pod not running
        logging_err_exit
    fi
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
    startclogen=$( oc get deploy/cluster-logging-operator -o jsonpath='{.metadata.generation}' )
    eopod=$( oc -n $ESO_NS get pods | awk '/^elasticsearch-operator-.* Running / {print $1}' )
    starteogen=$( oc -n $ESO_NS get deploy/elasticsearch-operator -o jsonpath='{.metadata.generation}' )

    if [ "${USE_IMAGE_STREAM:-false}" = true ] ; then
        # running in a dev env with imagestream builds
        OPENSHIFT_BUILD_NAMESPACE=${OPENSHIFT_BUILD_NAMESPACE:-openshift}
        registry=$( oc -n $OPENSHIFT_BUILD_NAMESPACE get is -l logging-infra=development -o jsonpath='{.items[0].status.dockerImageRepository}' | \
            sed 's,/[^/]*$,/,' )
        oc set env deploy/cluster-logging-operator --list | grep _IMAGE= | \
        sed -e '/docker.io\/openshift\/origin-logging-/ {s,docker.io/openshift/origin-,'"$registry"',}' \
            -e '/quay.io\/openshift\/origin-logging-/ {s,quay.io/openshift/origin-,'"$registry"',}' | \
        oc set env -e - deploy/cluster-logging-operator
        # special handling for rsyslog for now
        oc set env deploy/cluster-logging-operator RSYSLOG_IMAGE=${registry}logging-rsyslog:latest
    # update the images to use in the CLO
    else
        oc set env deploy/cluster-logging-operator \
            ELASTICSEARCH_IMAGE=$( construct_image_name logging-elasticsearch5 latest ) \
            KIBANA_IMAGE=$( construct_image_name logging-kibana5 latest ) \
            CURATOR_IMAGE=$( construct_image_name logging-curator5 latest ) \
            FLUENTD_IMAGE=$( construct_image_name logging-fluentd latest ) \
            RSYSLOG_IMAGE=$( construct_image_name logging-rsyslog latest )
        cloimg=$( construct_image_name cluster-logging-operator latest )
        eoimg=$( construct_image_name elasticsearch-operator latest )
        if [ "${USE_CLO_LATEST_IMAGE:-false}" = true -a -n "${cloimg:-}" ] ; then
            oc patch deploy/cluster-logging-operator --type=json \
                --patch '[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"'"$cloimg"'"}]'
        fi
        if [ "${USE_EO_LATEST_IMAGE:-false}" = true -a -n "${eoimg:-}" ] ; then
            oc -n $ESO_NS patch deploy/elasticsearch-operator --type=json \
                --patch '[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"'"$eoimg"'"}]'
            cureogen=$( oc -n $ESO_NS get deploy/elasticsearch-operator -o jsonpath='{.metadata.generation}' )
            # doing the oc patch will restart eo - check to make sure it was restarted
            eo_is_restarted() {
                # wait until the old eo pod is not running and a new one is
                if [ $starteogen -lt $cureogen ] && oc -n $ESO_NS get pods $eopod > /dev/null 2>&1 ; then
                    return 1 # supposed to be restarted but old pod is still running
                fi
                oc -n $ESO_NS get pods | grep -q '^elasticsearch-operator-.* Running'
            }
            if ! wait_for_condition eo_is_restarted $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
                echo ERROR: elasticsearch-operator pod was not restarted
                logging_err_exit
            fi
        fi
    fi

    curclogen=$( oc get deploy/cluster-logging-operator -o jsonpath='{.metadata.generation}' )
    # doing the oc set env and patch will restart clo - check to make sure it was restarted
    clo_is_restarted() {
        # wait until the old clo pod is not running and a new one is
        if [ $startclogen -lt $curclogen ] && oc get pods $clopod > /dev/null 2>&1 ; then
            return 1 # supposed to be restarted but old pod is still running
        fi
        oc get pods | grep -q '^cluster-logging-operator-.* Running'
    }
    if ! wait_for_condition clo_is_restarted $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
        echo ERROR: cluster-logging-operator pod was not restarted
        logging_err_exit
    fi

    oc set env deploy/cluster-logging-operator --list | grep _IMAGE=
fi

if [ "${LOGGING_DEPLOY_MODE:-install}" = install ] ; then
    oc -n $LOGGING_NS create -f ${CLUSTERLOGGING_CR_FILE:-$TEST_OBJ_DIR/cr.yaml}
fi

if [ -n "${LOGGING_IMAGE_PULL_POLICY:-}" ] ; then
    wait_func() {
        esdeploys=$( oc get deploy -l component=elasticsearch -o name 2> /dev/null | wc -l )
        if [ "${esdeploys:-0}" -lt $expectedes ] ; then
            return 1
        fi
        if ! oc get deploy/kibana > /dev/null 2>&1 ; then
            return 1
        fi
        if ! oc get ds/fluentd > /dev/null 2>&1 && ! oc get ds/rsyslog > /dev/null 2>&1 ; then
            return 1
        fi
        if ! oc get cronjob/curator > /dev/null 2>&1 ; then
            return 1
        fi
        # if we got here, everything is as it should be
        return 0
    }
    if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
        echo ERROR: operator did not create deployments after 300 seconds
        logging_err_exit
    fi
    # we have all of the deployment objects - change them all to use the given image pull policy
    for deploy in $( oc get deploy,ds -o name ) ; do
        ncontainers=$( oc get $deploy -o template='{{len .spec.template.spec.containers | println}}' )
        for ii in $( seq 0 $(( ncontainers - 1 )) ) ; do
            oc patch $deploy --type=json \
                    --patch '[{"op":"replace","path":"/spec/template/spec/containers/'$ii'/imagePullPolicy","value":"'"${LOGGING_IMAGE_PULL_POLICY}"'"}]'
        done
    done
    for deploy in $( oc get cronjob -o name ) ; do
        ncontainers=$( oc get $deploy -o template='{{len .spec.jobTemplate.spec.template.spec.containers | println}}' )
        for ii in $( seq 0 $(( ncontainers - 1 )) ) ; do
            oc patch $deploy --type=json \
                    --patch '[{"op":"replace","path":"/spec/jobTemplate/spec/template/spec/containers/'$ii'/imagePullPolicy","value":"'"${LOGGING_IMAGE_PULL_POLICY}"'"}]'
        done
    done
    # then fall through to the wait below to wait for the pods to come up
fi

wait_for_logging_is_running

if [ "${LOGGING_DEPLOY_MODE:-install}" = upgrade ] ; then
    # dump current images
    oc get deploy,ds,cronjob -o yaml | awk '/ image: / {print $2}' > $ARTIFACT_DIR/post-upgrade-images
fi

echo Logging successfully deployed

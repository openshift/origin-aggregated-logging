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
# You can do this even if you have built and pushed custom images to the
# cluster e.g. you want to do an upgrade test - first deploy with
# USE_CUSTOM_IMAGES=false, then edit the CR to use your custom
# images and do an upgrade

# Installation requires the cluster-logging-operator and elasticsearch-operator
# source.  By default, it will look for CLO in $CLO_DIR (default
# $GOPATH/src/github.com/openshift/cluster-logging-operator) - if not found,
# it will download the needed files from the given CLO_REPO under github.com (default `openshift`)
# using the given CLO_BRANCH (default `master`).  By default it will use the
# vendored EO source in the CLO `vendor` directory.  You can override this e.g
# to use your local dev clone of EO by specifying EO_DIR.
# If you have a specific CLO or EO image you want to use, specify them by using
# CLO_IMAGE and EO_IMAGE.

set -euo pipefail

logging_err_exit() {
    set +e
    {
        for ns in $LOGGING_NS $ESO_NS ; do
            oc -n $ns get subscription
            oc -n $ns get clusterserviceversion
            oc -n $ns get operatorgroup -o yaml
            oc -n $ns get catalogsource
            oc -n $ns get catalogsourceconfigs
            oc -n $ns get deploy
            oc -n $ns get pods
            oc -n $ns get elasticsearch -o yaml
            oc -n $ns get clusterlogging -o yaml
            oc -n $ns get cm
            oc -n $ns get events
            for p in $( oc -n $ns get pods -o jsonpath='{.items[*].metadata.name}' ) ; do
                oc -n $ns describe pod $p > ${ARTIFACT_DIR}/$p.describe 2>&1
                for container in $( oc -n $ns get po $p -o jsonpath='{.spec.containers[*].name}' ) ; do
                    oc -n $ns logs -c $container $p >> ${ARTIFACT_DIR}/$p.log 2>&1
                    oc -n $ns -c $container exec $p -- logs --all >> ${ARTIFACT_DIR}/$p.log 2>&1
                done
            done
            if [ $LOGGING_NS = $ESO_NS ] ; then
                break
            fi
        done
        oc get crds | egrep 'logging|elasticsearch'
        olmpod=$( oc -n openshift-operator-lifecycle-manager get pods | awk '/^olm-operator-.* Running / {print $1}' )
        oc -n openshift-operator-lifecycle-manager logs $olmpod > ${ARTIFACT_DIR}/olm.log 2>&1
    } > ${ARTIFACT_DIR}/logging_err_exit.log 2>&1
    set +x
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

get_github_directory() {
    local outputdir=$1
    local ghdir=$2
    local comp=$3
    local repo=${4:-openshift}
    local branch=${5:-master}
    local name
    local type
    local download_url
    if [ ! -d $outputdir/$ghdir ] ; then
        mkdir -p $outputdir/$ghdir
    fi
    pushd $outputdir/$ghdir > /dev/null
    curl -s https://api.github.com/repos/$repo/$comp/contents/$ghdir?ref=$branch | \
    jq  -r '.[] | .name + " " + .type + " " + .download_url' | \
    while read name type download_url ; do
        if [ $type = dir ] ; then
            get_github_directory $outputdir $ghdir/$name $comp $repo $branch
        elif [ $type = file ] ; then
            curl -sOLJ "$download_url"
        fi
    done
    popd > /dev/null
}

# rather than cloning the entire repo, just grab the files
# we require for deploying
get_operator_files() {
    local dir=$1
    local comp=$2
    local repo=${3:-openshift}
    local branch=${4:-master}
    if [ ! -d $dir ] ; then
        mkdir -p $dir
    fi
    pushd $dir > /dev/null
    # get Makefile, hack/, manifests/
    curl -sOLJ https://raw.githubusercontent.com/$repo/$comp/$branch/Makefile
    get_github_directory $dir hack $comp $repo $branch
    get_github_directory $dir manifests $comp $repo $branch
    popd > /dev/null
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

get_cluster_version_maj_min() {
    local clusterver=$( oc get clusterversion -o jsonpath='{.items[0].status.desired.version}' )
    if [[ "$clusterver" =~ ^([1-9]+)[.]([0-9]+)[.] ]] ; then
        CLUSTER_MAJ_VER=${BASH_REMATCH[1]}
        CLUSTER_MIN_VER=${BASH_REMATCH[2]}
        CLUSTER_MAJ_MIN=${CLUSTER_MAJ_VER}.${CLUSTER_MIN_VER}
    fi
}

MASTER_RELEASE_VERSION=${MASTER_RELEASE_VERSION:-4.7}
get_cluster_version_maj_min
# what numeric version does master correspond to?
MASTER_VERSION=${MASTER_VERSION:-${CLUSTER_MAJ_MIN:-4.7}}
# what namespace to use for operator images?
EXTERNAL_REGISTRY=${EXTERNAL_REGISTRY:-registry.ci.openshift.org}
EXT_REG_IMAGE_NS=${EXT_REG_IMAGE_NS:-origin}
# for dev purposes, image builds will typically be pushed to this namespace
OPENSHIFT_BUILD_NAMESPACE=${OPENSHIFT_BUILD_NAMESPACE:-openshift}

LOGGING_IS=${LOGGING_IS:-logging}
LOGGING_VERSION=${LOGGING_VERSION:-5.0}
export IMAGE_ELASTICSEARCH6=${IMAGE_ELASTICSEARCH6:-registry.ci.openshift.org/${LOGGING_IS}/${LOGGING_VERSION}:logging-elasticsearch6}
export IMAGE_LOGGING_KIBANA6=${IMAGE_LOGGING_KIBANA6:-registry.ci.openshift.org/${LOGGING_IS}/${LOGGING_VERSION}:logging-kibana6}
export IMAGE_LOGGING_CURATOR5=${IMAGE_LOGGING_CURATOR5:-registry.ci.openshift.org/${LOGGING_IS}/${LOGGING_VERSION}:logging-curator5}
export IMAGE_LOGGING_FLUENTD=${IMAGE_LOGGING_FLUENTD:-registry.ci.openshift.org/${LOGGING_IS}/${LOGGING_VERSION}:logging-fluentd}
export IMAGE_ELASTICSEARCH_PROXY=${IMAGE_ELASTICSEARCH_PROXY:-registry.ci.openshift.org/${LOGGING_IS}/${LOGGING_VERSION}:elasticsearch-proxy}
export IMAGE_ELASTICSEARCH_OPERATOR_REGISTRY=${IMAGE_ELASTICSEARCH_OPERATOR_REGISTRY:-registry.ci.openshift.org/${LOGGING_IS}/${LOGGING_VERSION}:elasticsearch-operator-registry}
export IMAGE_CLUSTER_LOGGING_OPERATOR_REGISTRY=${IMAGE_CLUSTER_LOGGING_OPERATOR_REGISTRY:-registry.ci.openshift.org/${LOGGING_IS}/${LOGGING_VERSION}:cluster-logging-operator-registry}
export IMAGE_OAUTH_PROXY=${IMAGE_OAUTH_PROXY:-registry.ci.openshift.org/ocp/${MASTER_VERSION}:oauth-proxy}

construct_image_name() {
    local component="$1"
    local tagsuffix="${2:-latest}"
    # if running in CI environment, IMAGE_FORMAT will look like this:
    # IMAGE_FORMAT=registry.ci.openshift.org/ci-op-xxx/stable:${component}
    # stable is the imagestream containing the images built for this PR, or
    # otherwise the most recent image
    if [ -n "${IMAGE_FORMAT:-}" ] ; then
        if [ -n "${LOGGING_IMAGE_STREAM:-}" -a "${LOGGING_IMAGE_STREAM:-}" != 'stable' ] ; then
            local match=/stable:
            local replace="/${LOGGING_IMAGE_STREAM}:"
            IMAGE_FORMAT=${IMAGE_FORMAT/$match/$replace}
            if [ -n "${LOGGING_IMAGE_STREAM_NS:-}" -a "${LOGGING_IMAGE_STREAM_NS:-}" != 'ocp' ] ; then
                local ns=$(echo ${IMAGE_FORMAT} | cut -d '/' -f 2)
                IMAGE_FORMAT=${IMAGE_FORMAT/$ns/$LOGGING_IMAGE_STREAM_NS}
            fi
        fi
        echo ${IMAGE_FORMAT/'${component}'/$component}
    elif [ "${USE_CUSTOM_IMAGES:-true}" = false ] ; then
        echo $EXTERNAL_REGISTRY/$EXT_REG_IMAGE_NS/$MASTER_VERSION:$component
    elif oc -n ${OPENSHIFT_BUILD_NAMESPACE} get istag origin-${component}:$tagsuffix > /dev/null 2>&1 ; then
        oc -n ${OPENSHIFT_BUILD_NAMESPACE} get istag origin-${component}:$tagsuffix -o jsonpath='{.image.dockerImageReference}'
    else
        # fallback to latest externally available image
        echo $EXTERNAL_REGISTRY/$EXT_REG_IMAGE_NS/$MASTER_VERSION:$component
    fi
}

update_images_in_clo_yaml() {
    local yamlfile=$1
    local clo_img=${2:-} #unused.  leaving for compatibility
    local version=${3:-latest} #unused. leaving for compatibility
    local filearg
    if [ "$yamlfile" = "-" ] ; then
        filearg=""
    else
        filearg="-i $yamlfile"
    fi
    sed -e "/name: ELASTICSEARCH_IMAGE/,/value:/s,value:.*\$,value: ${IMAGE_ELASTICSEARCH6}," \
        -e "/name: KIBANA_IMAGE/,/value:/s,value:.*\$,value: ${IMAGE_LOGGING_KIBANA6}," \
        -e "/name: CURATOR_IMAGE/,/value:/s,value:.*\$,value: ${IMAGE_LOGGING_CURATOR5}," \
        -e "/name: FLUENTD_IMAGE/,/value:/s,value:.*\$,value: ${IMAGE_LOGGING_FLUENTD}," \
        -e "/name: OAUTH_PROXY_IMAGE/,/value:/s,value:.*\$,value: ${IMAGE_OAUTH_PROXY}," \
        -e "/name: ELASTICSEARCH_PROXY/,/value:/s,value:.*\$,value: ${IMAGE_ELASTICSEARCH_PROXY}," \
        $filearg
}

wait_for_logging_is_running() {
    # we expect a fluentd running on each node
    expectedcollectors=$( oc get nodes | grep -c " Ready " )
    echo INFO: Expecting $expectedcollectors collector to start
    # we expect $nodeCount elasticsearch pods
    es_ready="false"
    fluent_ready="false"
    kibana_ready="false"
    wait_func() {
        result=0
        local actuales=$( oc -n ${LOGGING_NS} get pods -l component=elasticsearch 2> /dev/null | grep -c 'elasticsearch.* 2/2 .*Running' )
        if [ $expectedes -ne ${actuales:-0} ] ; then
            echo WARN: ${actuales:-0} of $expectedes elasticsearch Running
            result=1
        else
            if [ "$es_ready" != "true" ] ; then
                echo INFO: Elasticsearch is Running
                export es_ready="true"
                #HACK cycle kibana pods
                #HACK TO figure out why kibana doesn't cycle
                oc -n ${LOGGING_NS} delete pods -l component=kibana --grace-period=0 --force
            fi
        fi
        if ! oc -n ${LOGGING_NS} get pods -l component=kibana 2> /dev/null | grep -q 'kibana.* 2/2 .*Running' ; then
            echo WARN: Kibana pod not running
            result=1
        else
            if [ "$kibana_ready" != "true" ] ; then
                echo INFO: Kibana is Running
                export kibana_ready="true"
            fi
        fi
        local actualcollectors=$( oc -n ${LOGGING_NS} get pods -l component=fluentd 2> /dev/null | grep -c "fluentd.*Running" )
        if [ $expectedcollectors -ne ${actualcollectors:-0} ] ; then
            echo WARN: ${actualcollectors:-0} of $expectedcollectors fluentd Running
            result=1
        else
            if [ "$fluent_ready" != "true" ] ; then
                echo INFO: Collectors are Running
                export fluent_ready="true"
            fi
        fi
        # if we got here, everything is as it should be
        return $result
    }
    if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
        echo ERROR: operator did not start pods after $DEFAULT_TIMEOUT seconds
        logging_err_exit
    fi
}

deploy_logging_using_olm() {
    local manifest=$( mktemp -d )
    trap "rm -rf $manifest" RETURN

    local CREATE_OPERATORGROUP=true
    if [ $ESO_NS = $LOGGING_NS ] ; then
        CREATE_OPERATORGROUP=false
    fi

    OPERATOR_LOGGING_IMAGE_STREAM=${OPERATOR_LOGGING_IMAGE_STREAM:-"stable"}
    local eoimg=${EO_IMAGE:-$( LOGGING_IMAGE_STREAM_NS=ocp LOGGING_IMAGE_STREAM=$OPERATOR_LOGGING_IMAGE_STREAM construct_image_name elasticsearch-operator latest )}
    cp -r ${EO_DIR}/manifests/${EO_MANIFEST_VER:-$MASTER_VERSION} $manifest
    cp ${EO_DIR}/manifests/*.package.yaml $manifest
    update_images_in_clo_yaml $manifest/${EO_MANIFEST_VER:-$MASTER_VERSION}/elasticsearch-operator.*.clusterserviceversion.yaml $eoimg
    for pkg in $manifest/*.package.yaml ; do
        sed -e 's/name: \([0-9.][0-9.]*\)$/name: "\1"/' -i $pkg
    done
    SUFFIX="-eo" \
    CONFIGMAP_NAME=eo-olm \
    NAMESPACE=${ESO_NS} \
    VERSION=${EO_MANIFEST_VER:-$MASTER_VERSION} \
    OPERATOR_IMAGE=$eoimg \
    MANIFEST_DIR=${manifest} \
    TEST_NAMESPACE=${ESO_NS} \
    TARGET_NAMESPACE=all \
    hack/vendor/olm-test-script/e2e-olm.sh

    local cloimg=${CLO_IMAGE:-$( LOGGING_IMAGE_STREAM_NS=ocp LOGGING_IMAGE_STREAM=$OPERATOR_LOGGING_IMAGE_STREAM construct_image_name cluster-logging-operator latest )}
    rm -rf $manifest/*
    cp -r ${CLO_DIR}/manifests/${CLO_MANIFEST_VER:-$MASTER_VERSION} $manifest
    cp ${CLO_DIR}/manifests/*.package.yaml $manifest
    update_images_in_clo_yaml $manifest/${CLO_MANIFEST_VER:-$MASTER_VERSION}/cluster-logging.*.clusterserviceversion.yaml $cloimg
    for pkg in $manifest/*.package.yaml ; do
        sed -e 's/name: \([0-9.][0-9.]*\)$/name: "\1"/' -i $pkg
    done
    SUFFIX="-clo" \
    CONFIGMAP_NAME=clo-olm \
    CREATE_OPERATORGROUP=${CREATE_OPERATORGROUP} \
    NAMESPACE=${LOGGING_NS} \
    VERSION=${CLO_MANIFEST_VER:-$MASTER_VERSION} \
    OPERATOR_IMAGE=$cloimg \
    MANIFEST_DIR=${manifest} \
    TEST_NAMESPACE=${LOGGING_NS} \
    TARGET_NAMESPACE=${LOGGING_NS} \
    hack/vendor/olm-test-script/e2e-olm.sh
}

deploy_logging_using_clo_make() {
    # edit the deployment manifest - use the images provided by CI or from api.ci registry
    pushd $EO_DIR > /dev/null
        make elasticsearch-catalog-deploy
        make elasticsearch-operator-install
    popd > /dev/null
    pushd $CLO_DIR > /dev/null
        make cluster-logging-catalog-deploy
        make cluster-logging-operator-install
    popd > /dev/null
}


disable_cvo() {
    local cvopod=$( oc -n openshift-cluster-version get pods | awk '/^cluster-version-operator-.* Running / {print $1}' ) || :
    if [ -z "$cvopod" ] ; then
        return 0
    fi
    oc -n openshift-cluster-version scale --replicas=0 deploy/cluster-version-operator
    wait_func() {
        oc -n openshift-cluster-version get pod $cvopod > /dev/null 2>&1
    }
    if ! wait_for_condition wait_func > ${ARTIFACT_DIR}/test_output 2>&1 ; then
        echo ERROR: could not stop cvo pod $cvopod
        logging_err_exit
    fi
}

disable_olm() {
    local olmpod=$( oc -n openshift-operator-lifecycle-manager get pods | awk '/^olm-operator-.* Running / {print $1}' ) || :
    if [ -z "$olmpod" ] ; then
        return 0
    fi
    oc -n openshift-operator-lifecycle-manager scale --replicas=0 deploy/olm-operator
    wait_func() {
        oc -n openshift-operator-lifecycle-manager get pod $olmpod > /dev/null 2>&1
    }
    if ! wait_for_condition wait_func > ${ARTIFACT_DIR}/test_output 2>&1 ; then
        echo ERROR: could not stop olm pod $olmpod
        logging_err_exit
    fi
}

get_latest_ver_from_manifest_dir() {
    find "$1" -maxdepth 1 -type d -regex '.*/manifests/[1-9]+[.][0-9]+' -printf '%f\n' | sort -n | tail -1
}

DEFAULT_TIMEOUT=${DEFAULT_TIMEOUT:-600}

switch_to_admin_user

LOGGING_NS=openshift-logging
ESO_NS=openshift-operators-redhat


TEST_OBJ_DIR=${TEST_OBJ_DIR:-openshift/ci-operator/build-image}
ARTIFACT_DIR=${ARTIFACT_DIR:-"$( pwd )/_output"}
if [ ! -d $ARTIFACT_DIR ] ; then
    mkdir -p $ARTIFACT_DIR
fi

# Create the $LOGGING_NS namespace:
if oc get project $LOGGING_NS > /dev/null 2>&1 ; then
    echo using existing project $LOGGING_NS
else
    oc adm new-project $LOGGING_NS --node-selector=''
fi

oc project ${LOGGING_NS}

if [ "${LOGGING_DEPLOY_MODE:-install}" = install ] ; then
    expectedes=$( awk '/nodeCount:/ {print $2}' ${CLUSTERLOGGING_CR_FILE:-$TEST_OBJ_DIR/cr.yaml} )
else
    expectedes=$( oc get clusterlogging instance -o jsonpath='{.spec.logStore.elasticsearch.nodeCount}' )
fi

if [ "${LOGGING_DEPLOY_MODE:-install}" = install ] ; then
    CLO_DIR=$GOPATH/src/github.com/openshift/cluster-logging-operator
    EO_DIR=$GOPATH/src/github.com/openshift/elasticsearch-operator
    if [ ! -d $GOPATH/src/github.com/openshift ] ; then
        mkdir -p $GOPATH/src/github.com/openshift
    fi
    pushd $GOPATH/src/github.com/openshift
        if [ ! -d cluster-logging-operator ] ; then
            git clone https://github.com/openshift/cluster-logging-operator
            pushd cluster-logging-operator
             git checkout ${CLO_BRANCH}
            popd
        fi
        if [ ! -d elasticsearch-operator ] ; then
            git clone https://github.com/openshift/elasticsearch-operator
            pushd elasticsearch-operator
              git checkout ${EO_BRANCH}
            popd
        fi
    popd

    deploy_logging_using_clo_make

    wait_func() {
        oc -n $ESO_NS get pods 2> /dev/null | grep -q 'elasticsearch-operator.*Running' && \
        oc -n $LOGGING_NS get pods 2> /dev/null | grep -q 'cluster-logging-operator.*Running'
    }
    if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
        echo ERROR: one of or both of elasticsearch-operator and cluster-logging-operator pod not running
        logging_err_exit
    fi
    oc -n $LOGGING_NS create -f ${CLUSTERLOGGING_CR_FILE:-$TEST_OBJ_DIR/cr.yaml}
    wait_for_logging_is_running
else
    # expect everything is already running
    wait_for_logging_is_running
    # dump current images
    oc get deploy,ds,cronjob -o yaml | awk '/ image: / {print $2}' > $ARTIFACT_DIR/pre-upgrade-images
    # if elasticsearch-operator is running in $LOGGING_NS, then set ESO_NS=$LOGGING_NS
    if oc get deploy/elasticsearch-operator -o name > /dev/null 2>&1 ; then
        ESO_NS=$LOGGING_NS
    fi
    # we need to make changes to clo and eo
    disable_cvo
    disable_olm

    clopod=$( oc get pods | awk '/^cluster-logging-operator-.* Running / {print $1}' )
    eopod=$( oc -n $ESO_NS get pods | awk '/^elasticsearch-operator-.* Running / {print $1}' )
    cloimg=$( construct_image_name cluster-logging-operator latest )
    eoimg=$( construct_image_name elasticsearch-operator latest )

    oc get deploy/cluster-logging-operator -o yaml | \
    update_images_in_clo_yaml - $cloimg | \
    oc replace --force -f -

    if [ "${USE_EO_LATEST_IMAGE:-false}" = true -a -n "${eoimg:-}" ] ; then
        oc -n $ESO_NS patch deploy/elasticsearch-operator --type=json \
            --patch '[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"'"$eoimg"'"}]'
        # doing the oc patch will restart eo - check to make sure it was restarted
        eo_is_restarted() {
            # wait until the old eo pod is not running and a new one is
            if oc -n $ESO_NS get pods $eopod > /dev/null 2>&1 ; then
                return 1 # supposed to be restarted but old pod is still running
            fi
            oc -n $ESO_NS get pods | grep -q '^elasticsearch-operator-.* Running'
        }
        if ! wait_for_condition eo_is_restarted $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
            echo ERROR: elasticsearch-operator pod was not restarted
            logging_err_exit
        fi
    fi

    # doing the oc set env and patch will restart clo - check to make sure it was restarted
    clo_is_restarted() {
        # wait until the old clo pod is not running and a new one is
        if oc get pods $clopod > /dev/null 2>&1 ; then
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

if [ -n "${LOGGING_IMAGE_PULL_POLICY:-}" ] ; then
    wait_func() {
        esdeploys=$( oc get deploy -l component=elasticsearch -o name 2> /dev/null | wc -l )
        if [ "${esdeploys:-0}" -lt $expectedes ] ; then
            return 1
        fi
        if ! oc get deploy/kibana > /dev/null 2>&1 ; then
            return 1
        fi
        if ! oc get ds/fluentd > /dev/null 2>&1 ; then
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

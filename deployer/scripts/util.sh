#!/bin/bash

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
        waittime=`expr $waittime - $interval`
    done
    if [ $complete = 0 ] ; then
        echo error builds are not complete
        oc get builds
        return 1
    fi
    return 0
}

function get_running_pod() {
    # $1 is component for selector
    oc get pods -l component=$1 | awk -v sel=$1 '$1 ~ sel && $3 == "Running" {print $1}'
}

function get_latest_pod() {

  label=$1

  local times=(`oc get pods -l $label -o jsonpath='{.items[*].metadata.creationTimestamp}' | xargs -n1 | sort -r | xargs`)
  local pod=$(oc get pods -l $label -o jsonpath="{.items[?(@.metadata.creationTimestamp==\"${times[0]}\")].metadata.name}")

  echo $pod
}

#!/bin/bash
# This tests for raw .operations index performance - write a bunch of messages
# to the system log and see how long it takes all of them to show up in ES

if [[ $VERBOSE ]]; then
  set -ex
else
  set -e
  VERBOSE=
fi
set -o nounset
set -o pipefail

if [[ $# -ne 1 || "$1" = "false" ]]; then
  # assuming not using OPS cluster
  CLUSTER="false"
  ops=
else
  CLUSTER="$1"
  ops="-ops"
fi

ARTIFACT_DIR=${ARTIFACT_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging}
if [ ! -d $ARTIFACT_DIR ] ; then
    mkdir -p $ARTIFACT_DIR
fi

# number of messages to send
NMESSAGES=${NMESSAGES:-10000}
# number size e.g. log base 10 of $NMESSAGES
NSIZE=${NSIZE:-5}
# printf format for message number
NFMT=${NFMT:-"%0${NSIZE}d"}
# size of each message - number of bytes to write to each line of the logger file, not
# the actual size of the JSON that is stored into ES
MSGSIZE=${MSGSIZE:-200}

USE_LOGGER=${USE_LOGGER:-false}

get_running_pod() {
    # $1 is component for selector
    oc get pods -l component=$1 | awk -v sel=$1 '$1 ~ sel && $3 == "Running" {print $1}'
}

wait_until_cmd() {
    ii=$2
    interval=${3:-10}
    while [ $ii -gt 0 ] ; do
        $1 && break
        sleep $interval
        ii=`expr $ii - $interval`
    done
    if [ $ii -le 0 ] ; then
        return 1
    fi
    return 0
}

# construct the logger file
loggerfile=`mktemp`
comparefile=$loggerfile
justthemessage=`mktemp`
ii=1
prefix=`uuidgen`
# need $MSGSIZE - (36 + "-" + $NSIZE + " ") bytes
n=`expr $MSGSIZE - 36 - 1 - $NSIZE - 1`
EXTRAFMT=${EXTRAFMT:-"%0${n}d"}
echo writing $NMESSAGES messages to file $loggerfile with prefix $prefix
while [ $ii -le $NMESSAGES ] ; do
    if [ "$USE_LOGGER" = "true" ] ; then
        # format messages for use by logger
        printf "%s-$NFMT $EXTRAFMT\n" $prefix $ii 1 >> $loggerfile
    else
        # direct to /var/log/messages format
        printf "%s %s %s[%d]: %s-$NFMT $EXTRAFMT\n" "$(date +'%b %d %H:%M:%S')" `hostname -s` \
               $prefix $$ $prefix $ii 1 >> $loggerfile
        printf "%s-$NFMT $EXTRAFMT\n" $prefix $ii 1 >> $justthemessage
    fi
    ii=`expr $ii + 1`
done

# get current count of .operations
kpod=`get_running_pod kibana${ops}`
STARTTIME=$(date +%s)
if [ "$USE_LOGGER" = "true" ] ; then
    echo starting logger at `date`
    # there is some sort of throttling going on in journald?  rsyslog? only ~ 760 messages
    # end up in /var/log/messages
    echo logger -i -p local6.info -t $prefix -f $loggerfile
    time logger -i -p local6.info -t $prefix -f $loggerfile
    echo finished logger at `date`
else
    cat $loggerfile | sudo tee -a /var/log/messages > /dev/null    
    comparefile=$justthemessage
fi

# not used now, but in case we need it
INDEX_PREFIX=
count_ge_nmessages() {
    curcount=`oc exec $kpod -- curl -s -k --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
            https://logging-es${ops}:9200/${INDEX_PREFIX}.operations*/_count\?q=message:$prefix | \
            python -c 'import json, sys; print json.loads(sys.stdin.read())["count"]'`
    # output: time count 
    echo $(date +%s) $curcount
    test $curcount -ge $NMESSAGES
}

echo waiting for $NMESSAGES messages in elasticsearch

wait_until_cmd count_ge_nmessages 600 1
# now total number of records >= $startcount + $NMESSAGES
# mark time
MARKTIME=$(date +%s)

echo duration `expr $MARKTIME - $STARTTIME`

# search ES and extract the messages
esmessages=`mktemp`
oc exec $kpod -- curl -s -k --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
   https://logging-es${ops}:9200/${INDEX_PREFIX}.operations*/_search\?q=ident:$prefix\&fields=message\&size=`expr $NMESSAGES + 1` | \
    python -c 'import json, sys; print "\n".join([ii["fields"]["message"][0] for ii in json.loads(sys.stdin.read())["hits"]["hits"]])' | sort -n > $esmessages

diff $comparefile $esmessages
echo ES content is identical to log content

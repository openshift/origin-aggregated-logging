#!/bin/bash

set -euo pipefail

function get_running_pod() {
    # $1 is component for selector
    oc get pods -l component=$1 | awk -v sel=$1 '$1 ~ sel && $3 == "Running" {print $1}' | head -1
}

function query_es_from_es() {
    oc exec $1 -- curl --connect-timeout 1 -s -k \
       --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key \
       https://localhost:9200/${2}*/${3}\?"$4"
}

# read JSON query arguments from stdin
function query_es_from_es_json() {
    oc exec -i $1 -- curl --connect-timeout 1 -s -k \
       --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key \
       https://localhost:9200/${2}*/${3} -d@-
}

function get_url_path_of_record() {
    # returns $index/$type/$_id
    python -c "import json, sys; hsh = json.loads(sys.stdin.read())['hits']['hits'][0]; print '%(_index)s/%(_type)s/%(_id)s'.encode('utf-8') % hsh"
}

function get_last_field_from_es() {
    query_es_from_es $1 $2 _search "size=1\&sort=@{timefield}:desc" | \
        get_field_value_from_json $3
}

function get_last_url_from_es() {
    query_es_from_es $1 $2 _search "size=1&sort=${timefield}:desc${3:+&$3}" | \
        get_url_path_of_record
}

function get_field_value_from_record() {
    python -c 'import json, sys; print json.loads(sys.stdin.read())["_source"]["'"$1"'"].encode("utf-8")'
}

function get_field_value_from_es_url() {
    oc exec -i $1 -- curl --connect-timeout 1 -s -k \
       --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key \
       https://localhost:9200/$2 | get_field_value_from_record "$3"
}

# $1 - shell command or function to call to test if wait is over -
#      this command/function should return true if the condition
#      has been met, or false if still waiting for condition to be met
# $2 - shell command or function to call if we timed out for error handling
# $3 - timeout in seconds - should be a multiple of $4 (interval)
# $4 - loop interval in seconds
function wait_until_cmd_or_err() {
    let ii=$3
    local interval=${4:-1}
    while [ $ii -gt 0 ] ; do
        $1 && break
        sleep $interval
        let ii=ii-$interval
    done
    if [ $ii -le 0 ] ; then
        $2
        return 1
    fi
    return 0
}

debug() {
    if [ -n "${DEBUG:-}" ] ; then
        echo "$@"
    fi
}

verbose() {
    if [ -n "${VERBOSE:-}" ] ; then
        echo "$@"
    fi
}

err() {
    echo ERROR: "$@"
}

info() {
    echo "$@"
}

info_same() {
    verbose "$@"
}

info_diff() {
    # $X is $N $units behind $Y
    # or
    # $X is up-to-date with $Y
    if [ $2 = "0" -o $2 = "0.0" ] ; then
        info_same $1 is up-to-date with $4 in $3
    else
        info $1 is $2 $3 behind $4
    fi
}

es_pod=`get_running_pod es`
es_ops_pod=`get_running_pod es-ops 2> /dev/null`
es_ops_pod=${es_ops_pod:-$es_pod}

if grep -q -- '--log-driver=journald' /etc/sysconfig/docker ; then
    USE_JOURNAL=1
fi

# get es version - 2.x and later use @timestamp, earlier use time
esver=`oc exec $es_pod -- curl --connect-timeout 1 -s -k --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key https://localhost:9200/_cat/nodes?h=version`
case $esver in
    1.*) timefield=time; prj_prefix= ;;
    *) timefield=@timestamp; prj_prefix="project." ;;
esac

if [ -n "${USE_JOURNAL:-}" ] ; then
    journal_pos_err() {
        err timed out waiting for /var/log/journal.pos - check Fluentd pod log
        exit 1
    }
    wait_until_cmd_or_err "test -f /var/log/journal.pos" journal_pos_err 300
    # get cursor position
    cursor="`cat /var/log/journal.pos`"
    last_cursor="`journalctl -r -n 1 -o export|awk '/^__CURSOR=/ {print substr($0, 10)}'`"
    if [ "$cursor" = "$last_cursor" ] ; then
        :
    else
        nrecs=`journalctl -c "$cursor" | wc -l`
        nrecs=`expr $nrecs - 1` || : # -1 for header
    fi
    verbose last record read by Fluentd: `journalctl -c "$cursor" -n 1|tail -1`
    verbose last record in the journal: `journalctl -c "$last_cursor" -n 1|tail -1`
    last_srts=`journalctl -n 1 -o export -c "$last_cursor"|awk -F= '/^_SOURCE_REALTIME_TIMESTAMP/ {print $2}'`
    last_rts=`journalctl -n 1 -o export -c "$last_cursor"|awk -F= '/^__REALTIME_TIMESTAMP/ {print $2}'`
    last_ts=${last_srts:-$last_rts}
    srts=`journalctl -n 1 -o export -c "$cursor"|awk -F= '/^_SOURCE_REALTIME_TIMESTAMP/ {print $2}'`
    rts=`journalctl -n 1 -o export -c "$cursor"|awk -F= '/^__REALTIME_TIMESTAMP/ {print $2}'`
    ts=${srts:-$rts}
    if [ "$cursor" != "$last_cursor" ] ; then
        diff=`expr $last_ts - $ts` || :
        secdiff=`expr $diff / 1000000` || :
        usecdiff=`expr $diff % 1000000` || :
        info_diff Fluentd $secdiff.$usecdiff seconds "the journal"
        info_diff Fluentd $nrecs records "the journal"
    fi
    # find the last project record
    last_prj=`journalctl -o export -u docker | grep '^CONTAINER_NAME=k8s_'| grep -v '^CONTAINER_NAME=k8s_[^\.]\+\.[^_]\+_[^_]\+_\(default\|openshift-infra\|openshift\)_[^_]\+_[a-f0-9]\{8\}$'|tail -1`
    last_prj_cursor="`journalctl -n 1 -o export "$last_prj"|awk '/^__CURSOR=/ {print substr($0, 10)}'`"
    verbose last record from a project container: `journalctl -u docker -n 1 "$last_prj"|tail -1`
    prj_srts=`journalctl -n 1 -o export -c "$last_prj_cursor"|awk -F= '/^_SOURCE_REALTIME_TIMESTAMP/ {print $2}'`
    prj_rts=`journalctl -n 1 -o export -c "$last_prj_cursor"|awk -F= '/^__REALTIME_TIMESTAMP/ {print $2}'`
    prj_ts=${prj_srts:-$prj_rts}
    prj=`echo "$last_prj" | \
         sed -n '/^CONTAINER_NAME=/ {s/^CONTAINER_NAME=k8s_\([^\.]\+\)\.[^_]\+_\([^_]\+\)_\([^_]\+\)_[^_]\+_[a-f0-9]\{8\}$/\3/; p; q}'`

    # see if the fluentd record is for ops or projects
    namespace=`journalctl -n 1 -o export -c "$cursor" | \
        sed -n '/^CONTAINER_NAME=/ {s/^CONTAINER_NAME=k8s_\([^\.]\+\)\.[^_]\+_\([^_]\+\)_\([^_]\+\)_[^_]\+_[a-f0-9]\{8\}$/\3/; p; q}'`
    fluentd_rec_is_project=
    case "$namespace" in
        "") : ;; # ops
        "default"|"openshift-infra"|"openshift") : ;; # ops
        *) fluentd_rec_is_project=1 ;;
    esac

    # find the latest .operations.* and project.* records in Elasticsearch
    # compare them to the records with ${timefield} $ts and $prj_ts
    # find out how far behind ES is in both number of records and time

    # get url of last .operations record in ES
    # empty means no such index in ES yet
    es_ops_url=`get_last_url_from_es $es_ops_pod .operations.` || :
    # get timestamp of last .operations record in ES
    if [ -z "${es_ops_url:-}" ] ; then
        info Elasticsearch has no index or data for operations
    else
        es_ops_ts_str=`get_field_value_from_es_url $es_ops_pod $es_ops_url "${timefield}"`
        es_ops_ts=`date +%s%6N --date="$es_ops_ts_str"`
        # get message of last .operations record in ES
        es_ops_msg=`get_field_value_from_es_url $es_ops_pod $es_ops_url "message"`
        # find out how far behind journal es is for ops logs
        es_j_ops_diff=`expr $last_ts - $es_ops_ts` || :
        es_j_ops_diff_secs=`expr $es_j_ops_diff / 1000000` || :
        es_j_ops_diff_usecs=`expr $es_j_ops_diff % 1000000` || :
        info_diff "Elasticsearch operations index" $es_j_ops_diff_secs.$es_j_ops_diff_usecs seconds "the journal"
    fi

    # get url of last project. record in ES
    es_prj_url=`get_last_url_from_es $es_pod ${prj_prefix}$prj.` || :
    if [ -z "${es_prj_url:-}" ] ; then
        info Elasticsearch has no index or data for projects
    else
        # get timestamp of last project record in ES
        es_prj_ts_str=`get_field_value_from_es_url $es_pod $es_prj_url "${timefield}"`
        es_prj_ts=`date +%s%6N --date="$es_prj_ts_str"`
        # get message of last .operations record in ES
        es_prj_msg=`get_field_value_from_es_url $es_pod $es_prj_url "message"`
        # find out how far behind journal es is for project logs
        es_j_prj_diff=`expr $prj_ts - $es_prj_ts` || :
        es_j_prj_diff_secs=`expr $es_j_prj_diff / 1000000` || :
        es_j_prj_diff_usecs=`expr $es_j_prj_diff % 1000000` || :
        info_diff "Elasticsearch project index" $es_j_prj_diff_secs.$es_j_prj_diff_usecs seconds "the journal"
    fi

    # find out how far behind fluentd es is
    if [ -z "$fluentd_rec_is_project" ] ; then
        if [ -n "${es_ops_url:-}" ] ; then
            es_ops_diff=`expr $ts - $es_ops_ts` || :
            es_ops_diff_secs=`expr $es_ops_diff / 1000000` || :
            es_ops_diff_usecs=`expr $es_ops_diff % 1000000` || :
            info_diff "Elasticsearch operations index" $es_ops_diff_secs.$es_ops_diff_usecs seconds Fluentd
        fi
    else
        if [ -n "${es_ops_url:-}" ] ; then
            es_prj_diff=`expr $ts - $es_prj_ts` || :
            es_prj_diff_secs=`expr $es_prj_diff / 1000000` || :
            es_prj_diff_usecs=`expr $es_prj_diff % 1000000` || :
            info_diff "Elasticsearch project index" $es_prj_diff_secs.$es_prj_diff_usecs seconds Fluentd
        fi
    fi
else # use /var/log/messages and json-file docker logs
    node_pos_err() {
        err timed out waiting for /var/log/node.log.pos - check Fluentd pod log
        exit 1
    }
    wait_until_cmd_or_err "test -f /var/log/node.log.pos" node_pos_err 300
    cont_pos_err() {
        err timed out waiting for /var/log/es-containers.log.pos - check Fluentd pod log
        exit 1
    }
    wait_until_cmd_or_err "test -f /var/log/es-containers.log.pos" cont_pos_err 300

    totalfiles=0
    skippedfiles=0
    for file in /var/log/messages /var/log/containers/*.log ; do
        totalfiles=`expr $totalfiles + 1`
        src_offset=`ls -lL $file|awk '{print $5}'`
        if [ $src_offset = 0 ] ; then
            # file is empty - no records in es or fluentd either
            skippedfiles=`expr $skippedfiles + 1`
            verbose Skipping empty file $file
            continue
        fi

        if [ $file = /var/log/messages ] ; then
            posfile=/var/log/node.log.pos
            index=.operations.
            q=
            es_pod_to_use=$es_ops_pod
        else
            posfile=/var/log/es-containers.log.pos
            # get project from filename
            prj=`echo "$file" | sed 's,^/var/log/containers/[^_]\+_\([^_]\+\)_.*\.log$,\1,'`
            cont_id=`echo "$file" | sed 's,^/var/log/containers/.*-\([^\.]\+\).*\.log$,\1,'`
            case "$prj" in
                "") index=.operations.; es_pod_to_use=$es_ops_pod ;; # ops
                "default"|"openshift-infra"|"openshift") index=.operations.; es_pod_to_use=$es_ops_pod ;; # ops
                *) index="${prj_prefix}$prj."; es_pod_to_use=$es_pod ;;
            esac
            if [ -n "$cont_id" ] ; then
                q="q=docker.container_id:$cont_id"
            else
                q=
            fi
        fi
        # map file to ES index
        # get url of last matching document in ES
        es_url=`get_last_url_from_es $es_pod_to_use $index $q`
        if [ -z "$es_url" ] ; then
            es_ts=null
        else
            # get timestamp of ES document
            es_ts_str=`get_field_value_from_es_url $es_pod_to_use $es_url "${timefield}"`
            es_ts=`date +%s --date="$es_ts_str"`
            # get message of ES document
            es_msg=`get_field_value_from_es_url $es_pod_to_use $es_url "message"`
        fi

        # get the offset from the pos file - convert hex to decimal
        f_offset=`awk -v file=$file '$1 == file {ii=sprintf("0x%s", $2); print strtonum(ii)}' $posfile`
        if [ -z "$f_offset" -o "$f_offset" = 0 ] ; then
            # fluentd hasn't seen this file yet, or
            # no record read yet - assume diff from beginning of file
            f_offset=0
        fi
        f_rec=`head -c $f_offset $file | tail -1`
        src_offset=`ls -lL $file|awk '{print $5}'`
        src_rec=`tail -1 $file`
        if [ $file = /var/log/messages ] ; then
            f_date=`echo "$f_rec"| awk '{print $1, $2, $3}'`
            f_ts=`date --date="$f_date" +%s`
            src_date=`echo "$src_rec"| awk '{print $1, $2, $3}'`
            src_ts=`date --date="$src_date" +%s`
        else
            f_date=`echo "$f_rec" | python -c 'import sys,json; print json.loads(sys.stdin.read())["time"].encode("utf-8")'`
            f_ts=`date --date="$f_date" +%s`
            src_date=`echo "$src_rec" | python -c 'import sys,json; print json.loads(sys.stdin.read())["time"].encode("utf-8")'`
            src_ts=`date --date="$src_date" +%s`
        fi
        if [ $es_ts = null ] ; then
            info Elasticsearch $index index has no records for $file
        else
            info_diff "Elasticsearch $index index" `expr $src_ts - $es_ts` seconds $file
            info_diff "Elasticsearch $index index" `expr $f_ts - $es_ts` seconds "Fluentd for $file"
        fi
        info_diff Fluentd `expr $src_ts - $f_ts` seconds $file
        info_diff Fluentd `expr $src_offset - $f_offset` "bytes of offset" $file
        diff_recs=`tail -c +$f_offset $file | wc -l`
        diff_recs=`expr $diff_recs - 1` || : # for trailing nl
        info_diff Fluentd $diff_recs records $file
    done
    info Skipped $skippedfiles empty files of total $totalfiles
fi


# echo '{
#   "size": 1,
#   "sort": [{"${timefield}":"desc"}],
#   "query": {
#     "constant_score": {
#       "filter": {
#         "term": {"${timefield}":'"$ts_str"'}
#       }
#     }
#   }
# }' | query_es_from_es_json $espod .operations. _search

#!/bin/sh
set -euo pipefail

sed -i "s/es_host/$ES_HOST/" ${KIBANA_HOME}/config/kibana.yml
sed -i "s/es_port/$ES_PORT/" ${KIBANA_HOME}/config/kibana.yml

#set the max memory
BYTES_PER_MEG=$((1024*1024))
BYTES_PER_GIG=$((1024*${BYTES_PER_MEG}))

DEFAULT_MIN=$((128 * $BYTES_PER_MEG)) #This is a guess
regex='^([[:digit:]]+)([GgMm])?i?$'

export NODE_OPTIONS=""

if [[ "${KIBANA_MEMORY_LIMIT:-}" =~ $regex ]]; then
    num=${BASH_REMATCH[1]}
    unit=${BASH_REMATCH[2]}

    if [[ $unit =~ [Gg] ]]; then
        ((num = num * ${BYTES_PER_GIG})) # enables math to work out for odd Gi
    elif [[ $unit =~ [Mm] ]]; then
        ((num = num * ${BYTES_PER_MEG})) # enables math to work out for odd Gi
    #else assume bytes
    fi

    if [[ $num -lt $DEFAULT_MIN ]] ; then
        echo "$num is less then the default $(($DEFAULT_MIN / $BYTES_PER_MEG))m.  Setting to default."
        ((num = $DEFAULT_MIN))
    fi

    export NODE_OPTIONS="--max-old-space-size=$((num / ${BYTES_PER_MEG}))"

else
    echo "Unable to process the KIBANA_MEMORY_LIMIT: '${KIBANA_MEMORY_LIMIT}'.  It must be in the format of: /${regex}/"
    exit 1
fi

echo "Using NODE_OPTIONS: '$NODE_OPTIONS' Memory setting is in MB"

exec ${KIBANA_HOME}/bin/kibana

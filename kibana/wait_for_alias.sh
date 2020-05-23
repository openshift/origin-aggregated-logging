#!/bin/bash

required_alias=$1
required_index=$2

cat <<EOF >> js_script
const fss =require('fs');
const index = process.argv[2];
const data = fss.readFileSync('/dev/stdin').toString()
var indices = {};
try {
  indices = JSON.parse(data)
} catch(err) {
  console.error(err)
}
console.info(Object.keys(indices).some(e => e === index))
EOF

while [ true ]; do

  valid=$(curl -s --cacert /etc/kibana/keys/ca --key /etc/kibana/keys/key --cert /etc/kibana/keys/cert https://elasticsearch.openshift-logging.svc:9200/_alias/"$required_alias" | node/bin/node js_script "$required_index")

  if [[ "$valid" == "true" ]]; then
    echo "Required alias $required_alias for index $required_index valid"
    exit 0
  fi

  echo "Required alias $required_alias for index $required_index not valid"
  sleep 10s
done

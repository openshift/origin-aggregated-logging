#!/bin/bash
#
# Copyright 2017 Red Hat, Inc. and/or its affiliates
# and other contributors as indicated by the @author tags.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# TODO: try re-use code from ./run.sh
ES_REST_BASEURL=https://localhost:9200
EXPECTED_RESPONSE_CODE=200
EXPECTED_SG_DOCUMENT_COUNT=5
secret_dir=/etc/elasticsearch/secret
max_time=${READINESS_PROBE_TIMEOUT:-30}


function check_if_ready() {
  path="$1"
  err_msg="$2"
  response_code=$(curl -s --head \
      --cacert $secret_dir/admin-ca \
      --cert $secret_dir/admin-cert \
      --key  $secret_dir/admin-key \
      --max-time $max_time \
      -o /dev/null \
      -w '%{response_code}' \
      "${ES_REST_BASEURL}${path}")

  if [ "${response_code}" != ${EXPECTED_RESPONSE_CODE} ]; then
    echo "${err_msg} [response code: ${response_code}]"
    exit 1
  fi
}

check_if_ready "/" "Elasticsearch node is not ready to accept HTTP requests yet"
check_if_ready "/.searchguard.$DC_NAME" "Searchguard index '.searchguard.$DC_NAME' is missing in ES cluster"
sg_doc_count=$(curl -s --get \
  --cacert $secret_dir/admin-ca \
  --cert $secret_dir/admin-cert \
  --key  $secret_dir/admin-key \
  --max-time $max_time \
  "${ES_REST_BASEURL}/.searchguard.$DC_NAME/_search?size=0" \
  | python -c "import sys, json; print json.load(sys.stdin)['hits']['total']")

if [ "$sg_doc_count" != $EXPECTED_SG_DOCUMENT_COUNT ]; then
  echo "Incorrect SG document count, expected $EXPECTED_SG_DOCUMENT_COUNT [received doc count: ${sg_doc_count}]"
  exit 1
fi

for template_file in ${ES_HOME}/index_templates/*.json; do
  template=`basename $template_file`
  check_if_ready "/_template/$template" "Index template '$template' is missing in ES cluster"
done

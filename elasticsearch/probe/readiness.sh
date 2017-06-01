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
ES_REST_BASEURL=${ES_REST_BASEURL:-https://logging-es:9200}
EXPECTED_RESPONSE_CODE=200
secret_dir=/etc/elasticsearch/secret
max_time=${max_time:-4}

response_code=$(curl -s -X HEAD \
    --cacert $secret_dir/admin-ca \
    --cert $secret_dir/admin-cert \
    --key  $secret_dir/admin-key \
    --max-time $max_time \
    -w '%{response_code}' \
    "${ES_REST_BASEURL}/")

if [ ${response_code} == ${EXPECTED_RESPONSE_CODE} ]; then
  exit 0
else
  echo "Elasticsearch node is not ready to accept HTTP requests at ${ES_REST_BASEURL} [response code: ${response_code}]"
  exit 1
fi

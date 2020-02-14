#!/bin/bash -e
#
# Copyright 2018 Red Hat, Inc. and/or its affiliates
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

source "logging"

wait_for_port_open
failed=0

pushd "${ES_HOME}/init"
  files=$(ls --hide common | sort)
  for init_file in ${files}; do
    if [ -f "${init_file}" ] ; then
      ./"${init_file}" || { failed=1 ; echo "failed init: ${init_file}" >> ${HOME}/init_failures ; }
    fi
  done
popd

if [ $failed -eq 0 ]; then
  touch ${HOME}/init_complete
fi

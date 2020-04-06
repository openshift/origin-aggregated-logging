'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createOnPremElasticCloudInstructions = createOnPremElasticCloudInstructions;

var _i18n = require('@kbn/i18n');

var _instruction_variant = require('../../../common/tutorials/instruction_variant');

var _logstash_instructions = require('../../../common/tutorials/logstash_instructions');

var _onprem_cloud_instructions = require('../../../common/tutorials/onprem_cloud_instructions');

var _common_instructions = require('./common_instructions');

// TODO: compare with onPrem and elasticCloud scenarios and extract out common bits
function createOnPremElasticCloudInstructions() {
  const COMMON_NETFLOW_INSTRUCTIONS = (0, _common_instructions.createCommonNetflowInstructions)();
  const TRYCLOUD_OPTION1 = (0, _onprem_cloud_instructions.createTrycloudOption1)();
  const TRYCLOUD_OPTION2 = (0, _onprem_cloud_instructions.createTrycloudOption2)();
  const LOGSTASH_INSTRUCTIONS = (0, _logstash_instructions.createLogstashInstructions)();

  return {
    instructionSets: [{
      title: _i18n.i18n.translate('kbn.server.tutorials.netflow.onPremElasticCloudInstructions.title', {
        defaultMessage: 'Getting Started'
      }),
      instructionVariants: [{
        id: _instruction_variant.INSTRUCTION_VARIANT.OSX,
        instructions: [TRYCLOUD_OPTION1, TRYCLOUD_OPTION2, ...LOGSTASH_INSTRUCTIONS.INSTALL.OSX, ...COMMON_NETFLOW_INSTRUCTIONS.CONFIG.ON_PREM_ELASTIC_CLOUD.OSX, ...COMMON_NETFLOW_INSTRUCTIONS.SETUP.OSX]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.WINDOWS,
        instructions: [TRYCLOUD_OPTION1, TRYCLOUD_OPTION2, ...LOGSTASH_INSTRUCTIONS.INSTALL.WINDOWS, ...COMMON_NETFLOW_INSTRUCTIONS.CONFIG.ON_PREM_ELASTIC_CLOUD.WINDOWS, ...COMMON_NETFLOW_INSTRUCTIONS.SETUP.WINDOWS]
      }]
    }]
  };
} /*
   * Licensed to Elasticsearch B.V. under one or more contributor
   * license agreements. See the NOTICE file distributed with
   * this work for additional information regarding copyright
   * ownership. Elasticsearch B.V. licenses this file to you under
   * the Apache License, Version 2.0 (the "License"); you may
   * not use this file except in compliance with the License.
   * You may obtain a copy of the License at
   *
   *    http://www.apache.org/licenses/LICENSE-2.0
   *
   * Unless required by applicable law or agreed to in writing,
   * software distributed under the License is distributed on an
   * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
   * KIND, either express or implied.  See the License for the
   * specific language governing permissions and limitations
   * under the License.
   */
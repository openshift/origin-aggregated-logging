'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createElasticCloudInstructions = createElasticCloudInstructions;

var _i18n = require('@kbn/i18n');

var _instruction_variant = require('../../../common/tutorials/instruction_variant');

var _logstash_instructions = require('../../../common/tutorials/logstash_instructions');

var _common_instructions = require('./common_instructions');

// TODO: compare with onPremElasticCloud and onPrem scenarios and extract out common bits
/*
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

function createElasticCloudInstructions() {
  const COMMON_NETFLOW_INSTRUCTIONS = (0, _common_instructions.createCommonNetflowInstructions)();
  const LOGSTASH_INSTRUCTIONS = (0, _logstash_instructions.createLogstashInstructions)();

  return {
    instructionSets: [{
      title: _i18n.i18n.translate('kbn.server.tutorials.netflow.elasticCloudInstructions.title', {
        defaultMessage: 'Getting Started'
      }),
      instructionVariants: [{
        id: _instruction_variant.INSTRUCTION_VARIANT.OSX,
        instructions: [...LOGSTASH_INSTRUCTIONS.INSTALL.OSX, ...COMMON_NETFLOW_INSTRUCTIONS.CONFIG.ELASTIC_CLOUD.OSX, ...COMMON_NETFLOW_INSTRUCTIONS.SETUP.OSX]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.WINDOWS,
        instructions: [...LOGSTASH_INSTRUCTIONS.INSTALL.WINDOWS, ...COMMON_NETFLOW_INSTRUCTIONS.CONFIG.ELASTIC_CLOUD.WINDOWS, ...COMMON_NETFLOW_INSTRUCTIONS.SETUP.WINDOWS]
      }]
    }]
  };
}
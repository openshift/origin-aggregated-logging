'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createElasticCloudInstructions = createElasticCloudInstructions;

var _i18n = require('@kbn/i18n');

var _instruction_variant = require('../../../../common/tutorials/instruction_variant');

var _apm_agent_instructions = require('../instructions/apm_agent_instructions');

function getIfExists(config, key) {
  return config.has(key) && config.get(key);
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

function createElasticCloudInstructions(config) {
  const apmServerUrl = getIfExists(config, 'xpack.cloud.apm.url');
  const secretToken = getIfExists(config, 'xpack.cloud.apm.secret_token');

  return {
    instructionSets: [{
      title: _i18n.i18n.translate('kbn.server.tutorials.apm.elasticCloudInstructions.title', {
        defaultMessage: 'APM Agents'
      }),
      instructionVariants: [{
        id: _instruction_variant.INSTRUCTION_VARIANT.NODE,
        instructions: (0, _apm_agent_instructions.createNodeAgentInstructions)(apmServerUrl, secretToken)
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.DJANGO,
        instructions: (0, _apm_agent_instructions.createDjangoAgentInstructions)(apmServerUrl, secretToken)
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.FLASK,
        instructions: (0, _apm_agent_instructions.createFlaskAgentInstructions)(apmServerUrl, secretToken)
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.RAILS,
        instructions: (0, _apm_agent_instructions.createRailsAgentInstructions)(apmServerUrl, secretToken)
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.RACK,
        instructions: (0, _apm_agent_instructions.createRackAgentInstructions)(apmServerUrl, secretToken)
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.JS,
        instructions: (0, _apm_agent_instructions.createJsAgentInstructions)(apmServerUrl)
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.GO,
        instructions: (0, _apm_agent_instructions.createGoAgentInstructions)(apmServerUrl, secretToken)
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.JAVA,
        instructions: (0, _apm_agent_instructions.createJavaAgentInstructions)(apmServerUrl, secretToken)
      }]
    }]
  };
}
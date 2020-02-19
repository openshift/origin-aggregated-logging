'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.onPremInstructions = onPremInstructions;

var _i18n = require('@kbn/i18n');

var _instruction_variant = require('../../../../common/tutorials/instruction_variant');

var _apm_server_instructions = require('../instructions/apm_server_instructions');

var _apm_agent_instructions = require('../instructions/apm_agent_instructions');

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

function onPremInstructions(apmIndexPattern) {
  const EDIT_CONFIG = (0, _apm_server_instructions.createEditConfig)();
  const START_SERVER_UNIX = (0, _apm_server_instructions.createStartServerUnix)();
  const START_SERVER_UNIX_SYSV = (0, _apm_server_instructions.createStartServerUnixSysv)();

  return {
    instructionSets: [{
      title: _i18n.i18n.translate('kbn.server.tutorials.apm.apmServer.title', {
        defaultMessage: 'APM Server'
      }),
      instructionVariants: [{
        id: _instruction_variant.INSTRUCTION_VARIANT.OSX,
        instructions: [(0, _apm_server_instructions.createDownloadServerOsx)(), EDIT_CONFIG, START_SERVER_UNIX]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.DEB,
        instructions: [(0, _apm_server_instructions.createDownloadServerDeb)(), EDIT_CONFIG, START_SERVER_UNIX_SYSV]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.RPM,
        instructions: [(0, _apm_server_instructions.createDownloadServerRpm)(), EDIT_CONFIG, START_SERVER_UNIX_SYSV]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.WINDOWS,
        instructions: (0, _apm_server_instructions.createWindowsServerInstructions)()
      }],
      statusCheck: {
        title: _i18n.i18n.translate('kbn.server.tutorials.apm.apmServer.statusCheck.title', {
          defaultMessage: 'APM Server status'
        }),
        text: _i18n.i18n.translate('kbn.server.tutorials.apm.apmServer.statusCheck.text', {
          defaultMessage: 'Make sure APM Server is running before you start implementing the APM agents.'
        }),
        btnLabel: _i18n.i18n.translate('kbn.server.tutorials.apm.apmServer.statusCheck.btnLabel', {
          defaultMessage: 'Check APM Server status'
        }),
        success: _i18n.i18n.translate('kbn.server.tutorials.apm.apmServer.statusCheck.successMessage', {
          defaultMessage: 'You have correctly setup APM Server'
        }),
        error: _i18n.i18n.translate('kbn.server.tutorials.apm.apmServer.statusCheck.errorMessage', {
          defaultMessage: 'APM Server has still not connected to Elasticsearch'
        }),
        esHitsCheck: {
          index: apmIndexPattern,
          query: {
            bool: {
              filter: {
                exists: {
                  field: 'listening'
                }
              }
            }
          }
        }
      }
    }, {
      title: _i18n.i18n.translate('kbn.server.tutorials.apm.apmAgents.title', {
        defaultMessage: 'APM Agents'
      }),
      instructionVariants: [{
        id: _instruction_variant.INSTRUCTION_VARIANT.JAVA,
        instructions: (0, _apm_agent_instructions.createJavaAgentInstructions)()
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.JS,
        instructions: (0, _apm_agent_instructions.createJsAgentInstructions)()
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.NODE,
        instructions: (0, _apm_agent_instructions.createNodeAgentInstructions)()
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.DJANGO,
        instructions: (0, _apm_agent_instructions.createDjangoAgentInstructions)()
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.FLASK,
        instructions: (0, _apm_agent_instructions.createFlaskAgentInstructions)()
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.RAILS,
        instructions: (0, _apm_agent_instructions.createRailsAgentInstructions)()
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.RACK,
        instructions: (0, _apm_agent_instructions.createRackAgentInstructions)()
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.GO,
        instructions: (0, _apm_agent_instructions.createGoAgentInstructions)()
      }],
      statusCheck: {
        title: _i18n.i18n.translate('kbn.server.tutorials.apm.apmAgents.statusCheck.title', {
          defaultMessage: 'Agent status'
        }),
        text: _i18n.i18n.translate('kbn.server.tutorials.apm.apmAgents.statusCheck.text', {
          defaultMessage: 'Make sure your application is running and the agents are sending data.'
        }),
        btnLabel: _i18n.i18n.translate('kbn.server.tutorials.apm.apmAgents.statusCheck.btnLabel', {
          defaultMessage: 'Check agent status'
        }),
        success: _i18n.i18n.translate('kbn.server.tutorials.apm.apmAgents.statusCheck.successMessage', {
          defaultMessage: 'Data successfully received from one or more agents'
        }),
        error: _i18n.i18n.translate('kbn.server.tutorials.apm.apmAgents.statusCheck.errorMessage', {
          defaultMessage: 'No data has been received from agents yet'
        }),
        esHitsCheck: {
          index: apmIndexPattern,
          query: {
            bool: {
              should: [{ term: { 'processor.name': 'error' } }, { term: { 'processor.name': 'transaction' } }, { term: { 'processor.name': 'metric' } }, { term: { 'processor.name': 'sourcemap' } }]
            }
          }
        }
      }
    }]
  };
}
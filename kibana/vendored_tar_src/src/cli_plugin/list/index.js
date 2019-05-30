'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = pluginList;

var _utils = require('../../utils');

var _list = require('./list');

var _list2 = _interopRequireDefault(_list);

var _logger = require('../lib/logger');

var _logger2 = _interopRequireDefault(_logger);

var _settings = require('./settings');

var _log_warnings = require('../lib/log_warnings');

var _log_warnings2 = _interopRequireDefault(_log_warnings);

var _warn_if_plugin_dir_option = require('../lib/warn_if_plugin_dir_option');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

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

function processCommand(command, options) {
  let settings;
  try {
    settings = (0, _settings.parse)(command, options);
  } catch (ex) {
    //The logger has not yet been initialized.
    console.error(ex.message);
    process.exit(64); // eslint-disable-line no-process-exit
  }

  const logger = new _logger2.default(settings);

  (0, _warn_if_plugin_dir_option.warnIfUsingPluginDirOption)(settings, (0, _utils.fromRoot)('plugins'), logger);
  (0, _log_warnings2.default)(settings, logger);
  (0, _list2.default)(settings, logger);
}

function pluginList(program) {
  program.command('list').option('-d, --plugin-dir <path>', 'path to the directory where plugins are stored (DEPRECATED, known to not work for all plugins)', (0, _utils.fromRoot)('plugins')).description('list installed plugins').action(processCommand);
}
module.exports = exports['default'];
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.existingInstall = existingInstall;
exports.rebuildCache = rebuildCache;
exports.assertVersion = assertVersion;

var _path = require('path');

var _path2 = _interopRequireDefault(_path);

var _execa = require('execa');

var _execa2 = _interopRequireDefault(_execa);

var _utils = require('../../utils');

var _version = require('../../utils/version');

var _fs = require('fs');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function existingInstall(settings, logger) {
  try {
    (0, _fs.statSync)(_path2.default.join(settings.pluginDir, settings.plugins[0].name));

    logger.error(`Plugin ${settings.plugins[0].name} already exists, please remove before installing a new version`);
    process.exit(70); // eslint-disable-line no-process-exit
  } catch (e) {
    if (e.code !== 'ENOENT') throw e;
  }
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

async function rebuildCache(settings, logger) {
  logger.log('Optimizing and caching browser bundles...');

  const kibanaArgs = [(0, _utils.fromRoot)('./src/cli'), '--env.name=production', '--optimize.useBundleCache=false', '--server.autoListen=false', '--plugins.initialize=false'];

  const proc = (0, _execa2.default)(process.execPath, kibanaArgs, {
    stdio: ['ignore', 'pipe', 'pipe'],
    cwd: (0, _utils.fromRoot)('.')
  });

  await (0, _utils.watchStdioForLine)(proc, () => {}, /Optimization .+ complete/);
}

function assertVersion(settings) {
  if (!settings.plugins[0].kibanaVersion) {
    throw new Error(`Plugin package.json is missing both a version property (required) and a kibana.version property (optional).`);
  }

  const actual = (0, _version.cleanVersion)(settings.plugins[0].kibanaVersion);
  const expected = (0, _version.cleanVersion)(settings.version);
  if (!(0, _version.versionSatisfies)(actual, expected)) {
    throw new Error(`Plugin ${settings.plugins[0].name} [${actual}] is incompatible with Kibana [${expected}]`);
  }
}
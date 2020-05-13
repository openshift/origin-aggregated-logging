'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = list;

var _fs = require('fs');

var _path = require('path');

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

function list(settings, logger) {
  (0, _fs.readdirSync)(settings.pluginDir).forEach(filename => {
    const stat = (0, _fs.statSync)((0, _path.join)(settings.pluginDir, filename));

    if (stat.isDirectory() && filename[0] !== '.') {
      try {
        const packagePath = (0, _path.join)(settings.pluginDir, filename, 'package.json');
        const { version } = JSON.parse((0, _fs.readFileSync)(packagePath, 'utf8'));
        logger.log(filename + '@' + version);
      } catch (e) {
        throw new Error('Unable to read package.json file for plugin ' + filename);
      }
    }
  });
  logger.log(''); //intentional blank line for aesthetics
}
module.exports = exports['default'];
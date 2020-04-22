'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.setupLogging = setupLogging;
exports.loggingMixin = loggingMixin;

var _good = require('@elastic/good');

var _good2 = _interopRequireDefault(_good);

var _configuration = require('./configuration');

var _configuration2 = _interopRequireDefault(_configuration);

var _log_with_metadata = require('./log_with_metadata');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

async function setupLogging(server, config) {
  return await server.register({
    plugin: _good2.default,
    options: (0, _configuration2.default)(config)
  });
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

async function loggingMixin(kbnServer, server, config) {
  _log_with_metadata.logWithMetadata.decorateServer(server);
  return await setupLogging(server, config);
}
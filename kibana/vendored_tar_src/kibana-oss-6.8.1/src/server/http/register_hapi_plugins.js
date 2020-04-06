'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.registerHapiPlugins = registerHapiPlugins;

var _vision = require('vision');

var _vision2 = _interopRequireDefault(_vision);

var _inert = require('inert');

var _inert2 = _interopRequireDefault(_inert);

var _h2o = require('h2o2');

var _h2o2 = _interopRequireDefault(_h2o);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const plugins = [_vision2.default, _inert2.default, _h2o2.default]; /*
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

async function registerPlugins(server) {
  return await server.register(plugins);
}

function registerHapiPlugins(server) {
  registerPlugins(server);
}
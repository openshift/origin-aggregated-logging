'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.errorIfXPackInstall = errorIfXPackInstall;
exports.errorIfXPackRemove = errorIfXPackRemove;

var _is_oss = require('./is_oss');

function isXPack(plugin) {
  return (/x-pack/.test(plugin)
  );
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

function errorIfXPackInstall(settings) {
  if (isXPack(settings.plugin)) {
    if ((0, _is_oss.isOSS)()) {
      throw new Error('You are using the OSS-only distribution of Kibana.  ' + 'As of version 6.3+ X-Pack is bundled in the standard distribution of this software by default; ' + 'consequently it is no longer available as a plugin. Please use the standard distribution of Kibana to use X-Pack features.');
    } else {
      throw new Error('Kibana now contains X-Pack by default, there is no longer any need to install it as it is already present.');
    }
  }
}

function errorIfXPackRemove(settings) {
  if (isXPack(settings.plugin) && !(0, _is_oss.isOSS)()) {
    throw new Error('You are using the standard distribution of Kibana.  Please install the OSS-only distribution to remove X-Pack features.');
  }
}
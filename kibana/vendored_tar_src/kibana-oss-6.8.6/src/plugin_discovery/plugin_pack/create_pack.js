'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createPack$ = undefined;

var _plugin_pack = require('./plugin_pack');

var _operators = require('rxjs/operators');

var _errors = require('../errors');

function createPack(packageJson) {
  let provider = require(packageJson.directoryPath); // eslint-disable-line import/no-dynamic-require
  if (provider.__esModule) {
    provider = provider.default;
  }
  if (typeof provider !== 'function') {
    throw (0, _errors.createInvalidPackError)(packageJson.directoryPath, 'must export a function');
  }

  return new _plugin_pack.PluginPack({ path: packageJson.directoryPath, pkg: packageJson.contents, provider });
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

const createPack$ = exports.createPack$ = packageJson$ => packageJson$.pipe((0, _operators.map)(({ error, packageJson }) => {
  if (error) {
    return { error };
  }

  if (!packageJson) {
    throw new Error('packageJson is required to create the pack');
  }

  return {
    pack: createPack(packageJson)
  };
}),
// createPack can throw errors, and we want them to be represented
// like the errors we consume from createPackageJsonAtPath/Directory
(0, _operators.catchError)(error => [{ error }]));
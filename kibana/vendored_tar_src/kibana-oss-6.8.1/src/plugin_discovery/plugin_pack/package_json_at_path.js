'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createPackageJsonAtPath$ = undefined;

var _fs = require('fs');

var _rxjs = require('rxjs');

var Rx = _interopRequireWildcard(_rxjs);

var _operators = require('rxjs/operators');

var _path = require('path');

var _errors = require('../errors');

var _plugins = require('../../core/server/plugins');

var _lib = require('./lib');

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

async function createPackageJsonAtPath(path) {
  if (!(await (0, _lib.isDirectory)(path))) {
    throw (0, _errors.createInvalidPackError)(path, 'must be a directory');
  }

  let str;
  try {
    str = (0, _fs.readFileSync)((0, _path.resolve)(path, 'package.json'));
  } catch (err) {
    throw (0, _errors.createInvalidPackError)(path, 'must have a package.json file');
  }

  let pkg;
  try {
    pkg = JSON.parse(str);
  } catch (err) {
    throw (0, _errors.createInvalidPackError)(path, 'must have a valid package.json file');
  }

  return {
    directoryPath: path,
    contents: pkg
  };
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

const createPackageJsonAtPath$ = exports.createPackageJsonAtPath$ = path =>
// If plugin directory contains manifest file, we should skip it since it
// should have been handled by the core plugin system already.
Rx.defer(() => (0, _plugins.isNewPlatformPlugin)(path)).pipe((0, _operators.mergeMap)(isNewPlatformPlugin => isNewPlatformPlugin ? [] : createPackageJsonAtPath(path)), (0, _operators.map)(packageJson => ({ packageJson })), (0, _operators.catchError)(error => [{ error }]));
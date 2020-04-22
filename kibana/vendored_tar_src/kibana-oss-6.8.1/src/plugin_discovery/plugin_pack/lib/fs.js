'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createChildDirectory$ = undefined;
exports.isDirectory = isDirectory;

var _fs = require('fs');

var _path = require('path');

var _bluebird = require('bluebird');

var _rxjs = require('rxjs');

var Rx = _interopRequireWildcard(_rxjs);

var _operators = require('rxjs/operators');

var _errors = require('../../errors');

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

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

function assertAbsolutePath(path) {
  if (typeof path !== 'string') {
    throw (0, _errors.createInvalidDirectoryError)(new TypeError('path must be a string'), path);
  }

  if (!(0, _path.isAbsolute)(path)) {
    throw (0, _errors.createInvalidDirectoryError)(new TypeError('path must be absolute'), path);
  }
}

async function statTest(path, test) {
  try {
    const stats = await (0, _bluebird.fromNode)(cb => (0, _fs.stat)(path, cb));
    return Boolean(test(stats));
  } catch (error) {
    if (error.code !== 'ENOENT') {
      throw error;
    }
  }
  return false;
}

/**
 *  Determine if a path currently points to a directory
 *  @param  {String} path
 *  @return {Promise<boolean>}
 */
async function isDirectory(path) {
  assertAbsolutePath(path);
  return await statTest(path, stat => stat.isDirectory());
}

/**
 *  Get absolute paths for child directories within a path
 *  @param  {string} path
 *  @return {Promise<Array<string>>}
 */
const createChildDirectory$ = exports.createChildDirectory$ = path => Rx.defer(() => {
  assertAbsolutePath(path);
  return (0, _bluebird.fromNode)(cb => (0, _fs.readdir)(path, cb));
}).pipe((0, _operators.catchError)(error => {
  throw (0, _errors.createInvalidDirectoryError)(error, path);
}), (0, _operators.mergeAll)(), (0, _operators.filter)(name => !name.startsWith('.')), (0, _operators.map)(name => (0, _path.resolve)(path, name)), (0, _operators.mergeMap)(async absolute => {
  if (await isDirectory(absolute)) {
    return [absolute];
  } else {
    return [];
  }
}), (0, _operators.mergeAll)());
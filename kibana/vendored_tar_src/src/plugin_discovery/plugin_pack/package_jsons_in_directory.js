'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createPackageJsonsInDirectory$ = undefined;

var _operators = require('rxjs/operators');

var _errors = require('../errors');

var _lib = require('./lib');

var _package_json_at_path = require('./package_json_at_path');

/**
 *  Finds the plugins within a directory. Results are
 *  an array of objects with either `pack` or `error`
 *  keys.
 *
 *   - `{ error }` results are provided when the path is not
 *     a directory, or one of the child directories is not a
 *     valid plugin pack.
 *   - `{ pack }` results are for discovered plugins defs
 *
 *  @param  {String} path
 *  @return {Array<{pack}|{error}>}
 */
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

const createPackageJsonsInDirectory$ = exports.createPackageJsonsInDirectory$ = path => (0, _lib.createChildDirectory$)(path).pipe((0, _operators.mergeMap)(_package_json_at_path.createPackageJsonAtPath$), (0, _operators.catchError)(error => {
  // this error is produced by createChildDirectory$() when the path
  // is invalid, we return them as an error result similar to how
  // createPackAtPath$ works when it finds invalid packs in a directory
  if ((0, _errors.isInvalidDirectoryError)(error)) {
    return [{ error }];
  }

  throw error;
}));
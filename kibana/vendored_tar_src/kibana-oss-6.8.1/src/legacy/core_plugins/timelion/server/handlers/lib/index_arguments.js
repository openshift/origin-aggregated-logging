'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = indexArguments;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _i18n = require('@kbn/i18n');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// Only applies to already resolved arguments
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

function indexArguments(functionDef, orderedArgs) {

  const validateArg = require('./validate_arg')(functionDef);

  // This almost certainly is not required
  const allowedLength = functionDef.extended ? functionDef.args.length + 2 : functionDef.args.length;
  if (orderedArgs.length > allowedLength) {
    throw new Error(_i18n.i18n.translate('timelion.serverSideErrors.argumentsOverflowErrorMessage', {
      defaultMessage: 'Too many arguments passed to: {functionName}',
      values: {
        functionName: functionDef.name
      }
    }));
  }

  const indexedArgs = {};
  // Check and index each known argument
  _lodash2.default.each(functionDef.args, function (argDef, i) {
    const value = orderedArgs[i];
    validateArg(value, argDef.name, argDef);
    indexedArgs[argDef.name] = value;
  });

  // Also check and index the extended arguments if enabled
  if (functionDef.extended) {
    const values = orderedArgs[orderedArgs.length - 1];
    const names = orderedArgs[orderedArgs.length - 2];
    _lodash2.default.each(values, function (value, i) {
      validateArg(value, names[i], functionDef.extended);
      indexedArgs[names[i]] = value;
    });
  }

  return indexedArgs;
}
module.exports = exports['default'];
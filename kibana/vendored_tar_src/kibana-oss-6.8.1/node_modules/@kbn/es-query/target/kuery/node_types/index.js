'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.nodeTypes = undefined;

var _function = require('./function');

var functionType = _interopRequireWildcard(_function);

var _literal = require('./literal');

var literal = _interopRequireWildcard(_literal);

var _named_arg = require('./named_arg');

var namedArg = _interopRequireWildcard(_named_arg);

var _wildcard = require('./wildcard');

var wildcard = _interopRequireWildcard(_wildcard);

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

var nodeTypes = exports.nodeTypes = {
  function: functionType,
  literal: literal,
  namedArg: namedArg,
  wildcard: wildcard
};
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; /*
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

exports.buildNode = buildNode;
exports.buildNodeWithArgumentNodes = buildNodeWithArgumentNodes;
exports.toElasticsearchQuery = toElasticsearchQuery;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _functions = require('../functions');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function buildNode(functionName) {
  var kueryFunction = _functions.functions[functionName];

  if (_lodash2.default.isUndefined(kueryFunction)) {
    throw new Error('Unknown function "' + functionName + '"');
  }

  for (var _len = arguments.length, functionArgs = Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
    functionArgs[_key - 1] = arguments[_key];
  }

  return _extends({
    type: 'function',
    function: functionName
  }, kueryFunction.buildNodeParams.apply(kueryFunction, functionArgs));
}

// Mainly only useful in the grammar where we'll already have real argument nodes in hand
function buildNodeWithArgumentNodes(functionName, argumentNodes) {
  if (_lodash2.default.isUndefined(_functions.functions[functionName])) {
    throw new Error('Unknown function "' + functionName + '"');
  }

  return {
    type: 'function',
    function: functionName,
    arguments: argumentNodes
  };
}

function toElasticsearchQuery(node, indexPattern) {
  var kueryFunction = _functions.functions[node.function];
  return kueryFunction.toElasticsearchQuery(node, indexPattern);
}
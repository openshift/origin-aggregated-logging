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

exports.fromLiteralExpression = fromLiteralExpression;
exports.fromLegacyKueryExpression = fromLegacyKueryExpression;
exports.fromKueryExpression = fromKueryExpression;
exports.toElasticsearchQuery = toElasticsearchQuery;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _index = require('../node_types/index');

var _kuery = require('./kuery');

var _legacy_kuery = require('./legacy_kuery');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function fromLiteralExpression(expression, parseOptions) {
  parseOptions = _extends({}, parseOptions, {
    startRule: 'Literal'
  });

  return fromExpression(expression, parseOptions, _kuery.parse);
}

function fromLegacyKueryExpression(expression, parseOptions) {
  return fromExpression(expression, parseOptions, _legacy_kuery.parse);
}

function fromKueryExpression(expression, parseOptions) {
  return fromExpression(expression, parseOptions, _kuery.parse);
}

function fromExpression(expression) {
  var parseOptions = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
  var parse = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : _kuery.parse;

  if (_lodash2.default.isUndefined(expression)) {
    throw new Error('expression must be a string, got undefined instead');
  }

  parseOptions = _extends({}, parseOptions, {
    helpers: { nodeTypes: _index.nodeTypes }
  });

  return parse(expression, parseOptions);
}

// indexPattern isn't required, but if you pass one in, we can be more intelligent
// about how we craft the queries (e.g. scripted fields)
function toElasticsearchQuery(node, indexPattern) {
  if (!node || !node.type || !_index.nodeTypes[node.type]) {
    return toElasticsearchQuery(_index.nodeTypes.function.buildNode('and', []));
  }

  return _index.nodeTypes[node.type].toElasticsearchQuery(node, indexPattern);
}
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

exports.buildNodeParams = buildNodeParams;
exports.toElasticsearchQuery = toElasticsearchQuery;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _node_types = require('../node_types');

var _ast = require('../ast');

var ast = _interopRequireWildcard(_ast);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _toArray(arr) { return Array.isArray(arr) ? arr : Array.from(arr); }

function _toConsumableArray(arr) { if (Array.isArray(arr)) { for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) { arr2[i] = arr[i]; } return arr2; } else { return Array.from(arr); } } /*
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

function buildNodeParams(fieldName, params) {
  params = _lodash2.default.pick(params, 'topLeft', 'bottomRight');
  var fieldNameArg = _node_types.nodeTypes.literal.buildNode(fieldName);
  var args = _lodash2.default.map(params, function (value, key) {
    var latLon = value.lat + ', ' + value.lon;
    return _node_types.nodeTypes.namedArg.buildNode(key, latLon);
  });

  return {
    arguments: [fieldNameArg].concat(_toConsumableArray(args))
  };
}

function toElasticsearchQuery(node, indexPattern) {
  var _geo_bounding_box;

  var _node$arguments = _toArray(node.arguments),
      fieldNameArg = _node$arguments[0],
      args = _node$arguments.slice(1);

  var fieldName = _node_types.nodeTypes.literal.toElasticsearchQuery(fieldNameArg);
  var field = _lodash2.default.get(indexPattern, 'fields', []).find(function (field) {
    return field.name === fieldName;
  });
  var queryParams = args.reduce(function (acc, arg) {
    var snakeArgName = _lodash2.default.snakeCase(arg.name);
    return _extends({}, acc, _defineProperty({}, snakeArgName, ast.toElasticsearchQuery(arg)));
  }, {});

  if (field && field.scripted) {
    throw new Error('Geo bounding box query does not support scripted fields');
  }

  return {
    geo_bounding_box: (_geo_bounding_box = {}, _defineProperty(_geo_bounding_box, fieldName, queryParams), _defineProperty(_geo_bounding_box, 'ignore_unmapped', true), _geo_bounding_box)
  };
}
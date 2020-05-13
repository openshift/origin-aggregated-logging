'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.buildNodeParams = buildNodeParams;
exports.toElasticsearchQuery = toElasticsearchQuery;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _node_types = require('../node_types');

var _ast = require('../ast');

var ast = _interopRequireWildcard(_ast);

var _filters = require('../../filters');

var _get_fields = require('./utils/get_fields');

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
  params = _lodash2.default.pick(params, 'gt', 'lt', 'gte', 'lte', 'format');
  var fieldNameArg = typeof fieldName === 'string' ? ast.fromLiteralExpression(fieldName) : _node_types.nodeTypes.literal.buildNode(fieldName);
  var args = _lodash2.default.map(params, function (value, key) {
    return _node_types.nodeTypes.namedArg.buildNode(key, value);
  });

  return {
    arguments: [fieldNameArg].concat(_toConsumableArray(args))
  };
}

function toElasticsearchQuery(node, indexPattern) {
  var _node$arguments = _toArray(node.arguments),
      fieldNameArg = _node$arguments[0],
      args = _node$arguments.slice(1);

  var fields = indexPattern ? (0, _get_fields.getFields)(fieldNameArg, indexPattern) : [];
  var namedArgs = extractArguments(args);
  var queryParams = _lodash2.default.mapValues(namedArgs, ast.toElasticsearchQuery);

  // If no fields are found in the index pattern we send through the given field name as-is. We do this to preserve
  // the behaviour of lucene on dashboards where there are panels based on different index patterns that have different
  // fields. If a user queries on a field that exists in one pattern but not the other, the index pattern without the
  // field should return no results. It's debatable whether this is desirable, but it's been that way forever, so we'll
  // keep things familiar for now.
  if (fields && fields.length === 0) {
    fields.push({
      name: ast.toElasticsearchQuery(fieldNameArg),
      scripted: false
    });
  }

  var queries = fields.map(function (field) {
    if (field.scripted) {
      return {
        script: (0, _filters.getRangeScript)(field, queryParams)
      };
    }

    return {
      range: _defineProperty({}, field.name, queryParams)
    };
  });

  return {
    bool: {
      should: queries,
      minimum_should_match: 1
    }
  };
}

function extractArguments(args) {
  if (args.gt && args.gte || args.lt && args.lte) {
    throw new Error('range ends cannot be both inclusive and exclusive');
  }

  var unnamedArgOrder = ['gte', 'lte', 'format'];

  return args.reduce(function (acc, arg, index) {
    if (arg.type === 'namedArg') {
      acc[arg.name] = arg.value;
    } else {
      acc[unnamedArgOrder[index]] = arg;
    }

    return acc;
  }, {});
}
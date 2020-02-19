'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _slicedToArray = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }(); /*
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

exports.buildNodeParams = buildNodeParams;
exports.toElasticsearchQuery = toElasticsearchQuery;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _ast = require('../ast');

var ast = _interopRequireWildcard(_ast);

var _literal = require('../node_types/literal');

var literal = _interopRequireWildcard(_literal);

var _wildcard = require('../node_types/wildcard');

var wildcard = _interopRequireWildcard(_wildcard);

var _filters = require('../../filters');

var _get_fields = require('./utils/get_fields');

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _toConsumableArray(arr) { if (Array.isArray(arr)) { for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) { arr2[i] = arr[i]; } return arr2; } else { return Array.from(arr); } }

function buildNodeParams(fieldName, value) {
  var isPhrase = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;

  if (_lodash2.default.isUndefined(fieldName)) {
    throw new Error('fieldName is a required argument');
  }
  if (_lodash2.default.isUndefined(value)) {
    throw new Error('value is a required argument');
  }

  var fieldNode = typeof fieldName === 'string' ? ast.fromLiteralExpression(fieldName) : literal.buildNode(fieldName);
  var valueNode = typeof value === 'string' ? ast.fromLiteralExpression(value) : literal.buildNode(value);
  var isPhraseNode = literal.buildNode(isPhrase);

  return {
    arguments: [fieldNode, valueNode, isPhraseNode]
  };
}

function toElasticsearchQuery(node, indexPattern) {
  var _node$arguments = _slicedToArray(node.arguments, 3),
      fieldNameArg = _node$arguments[0],
      valueArg = _node$arguments[1],
      isPhraseArg = _node$arguments[2];

  var fieldName = ast.toElasticsearchQuery(fieldNameArg);
  var value = !_lodash2.default.isUndefined(valueArg) ? ast.toElasticsearchQuery(valueArg) : valueArg;
  var type = isPhraseArg.value ? 'phrase' : 'best_fields';

  if (fieldNameArg.value === null) {
    if (valueArg.type === 'wildcard') {
      return {
        query_string: {
          query: wildcard.toQueryStringQuery(valueArg)
        }
      };
    }

    return {
      multi_match: {
        type: type,
        query: value,
        lenient: true
      }
    };
  }

  var fields = indexPattern ? (0, _get_fields.getFields)(fieldNameArg, indexPattern) : [];

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

  var isExistsQuery = valueArg.type === 'wildcard' && value === '*';
  var isAllFieldsQuery = fieldNameArg.type === 'wildcard' && fieldName === '*' || fields && indexPattern && fields.length === indexPattern.fields.length;
  var isMatchAllQuery = isExistsQuery && isAllFieldsQuery;

  if (isMatchAllQuery) {
    return { match_all: {} };
  }

  var queries = fields.reduce(function (accumulator, field) {
    if (field.scripted) {
      // Exists queries don't make sense for scripted fields
      if (!isExistsQuery) {
        return [].concat(_toConsumableArray(accumulator), [{
          script: _extends({}, (0, _filters.getPhraseScript)(field, value))
        }]);
      }
    } else if (isExistsQuery) {
      return [].concat(_toConsumableArray(accumulator), [{
        exists: {
          field: field.name
        }
      }]);
    } else if (valueArg.type === 'wildcard') {
      return [].concat(_toConsumableArray(accumulator), [{
        query_string: {
          fields: [field.name],
          query: wildcard.toQueryStringQuery(valueArg)
        }
      }]);
    } else {
      var queryType = type === 'phrase' ? 'match_phrase' : 'match';
      return [].concat(_toConsumableArray(accumulator), [_defineProperty({}, queryType, _defineProperty({}, field.name, value))]);
    }
  }, []);

  return {
    bool: {
      should: queries,
      minimum_should_match: 1
    }
  };
}
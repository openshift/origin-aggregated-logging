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

exports.buildQueryFromKuery = buildQueryFromKuery;

var _kuery = require('../kuery');

function buildQueryFromKuery(indexPattern) {
  var queries = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : [];
  var allowLeadingWildcards = arguments[2];

  var queryASTs = queries.map(function (query) {
    try {
      return (0, _kuery.fromKueryExpression)(query.query, { allowLeadingWildcards: allowLeadingWildcards });
    } catch (parseError) {
      try {
        (0, _kuery.fromLegacyKueryExpression)(query.query);
      } catch (legacyParseError) {
        throw parseError;
      }
      throw Error('OutdatedKuerySyntaxError');
    }
  });
  return buildQuery(indexPattern, queryASTs);
}

function buildQuery(indexPattern, queryASTs) {
  var compoundQueryAST = _kuery.nodeTypes.function.buildNode('and', queryASTs);
  var kueryQuery = (0, _kuery.toElasticsearchQuery)(compoundQueryAST, indexPattern);
  return _extends({
    must: [],
    filter: [],
    should: [],
    must_not: []
  }, kueryQuery.bool);
}
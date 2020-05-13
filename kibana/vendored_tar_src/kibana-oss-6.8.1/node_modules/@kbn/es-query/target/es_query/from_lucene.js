'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.buildQueryFromLucene = buildQueryFromLucene;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _decorate_query = require('./decorate_query');

var _lucene_string_to_dsl = require('./lucene_string_to_dsl');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function buildQueryFromLucene(queries, queryStringOptions) {
  var combinedQueries = _lodash2.default.map(queries, function (query) {
    var queryDsl = (0, _lucene_string_to_dsl.luceneStringToDsl)(query.query);
    return (0, _decorate_query.decorateQuery)(queryDsl, queryStringOptions);
  });

  return {
    must: [].concat(combinedQueries),
    filter: [],
    should: [],
    must_not: []
  };
} /*
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
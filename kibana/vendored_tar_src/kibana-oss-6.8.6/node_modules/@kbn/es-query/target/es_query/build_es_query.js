'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.buildEsQuery = buildEsQuery;

var _lodash = require('lodash');

var _from_kuery = require('./from_kuery');

var _from_filters = require('./from_filters');

var _from_lucene = require('./from_lucene');

/**
 * @param indexPattern
 * @param queries - an array of query objects. Each query has a language property and a query property.
 * @param filters - an array of filter objects
 * @param config - an objects with query:allowLeadingWildcards and query:queryString:options UI
 * settings in form of { allowLeadingWildcards, queryStringOptions }
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

function buildEsQuery(indexPattern) {
  var queries = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : [];
  var filters = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : [];
  var config = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : {
    allowLeadingWildcards: false,
    queryStringOptions: {},
    ignoreFilterIfFieldNotInIndex: false
  };

  var validQueries = queries.filter(function (query) {
    return (0, _lodash.has)(query, 'query');
  });
  var queriesByLanguage = (0, _lodash.groupBy)(validQueries, 'language');

  var kueryQuery = (0, _from_kuery.buildQueryFromKuery)(indexPattern, queriesByLanguage.kuery, config.allowLeadingWildcards);
  var luceneQuery = (0, _from_lucene.buildQueryFromLucene)(queriesByLanguage.lucene, config.queryStringOptions);
  var filterQuery = (0, _from_filters.buildQueryFromFilters)(filters, indexPattern, config);

  return {
    bool: {
      must: [].concat(kueryQuery.must, luceneQuery.must, filterQuery.must),
      filter: [].concat(kueryQuery.filter, luceneQuery.filter, filterQuery.filter),
      should: [].concat(kueryQuery.should, luceneQuery.should, filterQuery.should),
      must_not: [].concat(kueryQuery.must_not, luceneQuery.must_not, filterQuery.must_not)
    }
  };
}
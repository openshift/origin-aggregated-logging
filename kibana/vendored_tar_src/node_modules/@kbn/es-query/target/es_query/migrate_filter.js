'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.migrateFilter = migrateFilter;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _filters = require('../filters');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; } /*
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

function migrateFilter(filter, indexPattern) {
  if (filter.match) {
    var fieldName = Object.keys(filter.match)[0];

    if (isMatchPhraseFilter(filter, fieldName)) {
      var params = _lodash2.default.get(filter, ['match', fieldName]);
      if (indexPattern) {
        var field = indexPattern.fields.find(function (f) {
          return f.name === fieldName;
        });
        if (field) {
          params.query = (0, _filters.getConvertedValueForField)(field, params.query);
        }
      }
      return {
        match_phrase: _defineProperty({}, fieldName, _lodash2.default.omit(params, 'type'))
      };
    }
  }

  return filter;
}

function isMatchPhraseFilter(filter, fieldName) {
  return _lodash2.default.get(filter, ['match', fieldName, 'type']) === 'phrase';
}
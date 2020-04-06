'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = query;

var _offset_time = require('../../offset_time');

var _offset_time2 = _interopRequireDefault(_offset_time);

var _get_interval_and_timefield = require('../../get_interval_and_timefield');

var _get_interval_and_timefield2 = _interopRequireDefault(_get_interval_and_timefield);

var _esQuery = require('@kbn/es-query');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function query(req, panel, series, esQueryConfig, indexPattern) {
  return next => doc => {
    const { timeField } = (0, _get_interval_and_timefield2.default)(panel, series);
    const { from, to } = (0, _offset_time2.default)(req, series.offset_time);

    doc.size = 0;
    const queries = !panel.ignore_global_filter ? req.payload.query : [];
    const filters = !panel.ignore_global_filter ? req.payload.filters : [];
    doc.query = (0, _esQuery.buildEsQuery)(indexPattern, queries, filters, esQueryConfig);

    const timerange = {
      range: {
        [timeField]: {
          gte: from.valueOf(),
          lte: to.valueOf(),
          format: 'epoch_millis'
        }
      }
    };
    doc.query.bool.must.push(timerange);

    if (panel.filter) {
      doc.query.bool.must.push({
        query_string: {
          query: panel.filter,
          analyze_wildcard: true
        }
      });
    }

    if (series.filter) {
      doc.query.bool.must.push({
        query_string: {
          query: series.filter,
          analyze_wildcard: true
        }
      });
    }

    return next(doc);
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

module.exports = exports['default'];
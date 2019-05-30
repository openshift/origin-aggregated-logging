'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = dateHistogram;

var _lodash = require('lodash');

var _get_bucket_size = require('../../helpers/get_bucket_size');

var _get_bucket_size2 = _interopRequireDefault(_get_bucket_size);

var _get_interval_and_timefield = require('../../get_interval_and_timefield');

var _get_interval_and_timefield2 = _interopRequireDefault(_get_interval_and_timefield);

var _get_timerange = require('../../helpers/get_timerange');

var _get_timerange2 = _interopRequireDefault(_get_timerange);

var _calculate_agg_root = require('./calculate_agg_root');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function dateHistogram(req, panel) {
  return next => doc => {
    const { timeField, interval } = (0, _get_interval_and_timefield2.default)(panel);
    const { bucketSize, intervalString } = (0, _get_bucket_size2.default)(req, interval);
    const { from, to } = (0, _get_timerange2.default)(req);
    panel.series.forEach(column => {
      const aggRoot = (0, _calculate_agg_root.calculateAggRoot)(doc, column);
      (0, _lodash.set)(doc, `${aggRoot}.timeseries.date_histogram`, {
        field: timeField,
        interval: intervalString,
        min_doc_count: 0,
        extended_bounds: {
          min: from.valueOf(),
          max: to.valueOf()
        }
      });
      (0, _lodash.set)(doc, aggRoot.replace(/\.aggs$/, '.meta'), {
        timeField,
        intervalString,
        bucketSize
      });
    });
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
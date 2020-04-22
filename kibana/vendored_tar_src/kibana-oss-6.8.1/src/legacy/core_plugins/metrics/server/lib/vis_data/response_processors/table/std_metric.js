'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = stdMetric;

var _get_splits = require('../../helpers/get_splits');

var _get_splits2 = _interopRequireDefault(_get_splits);

var _get_last_metric = require('../../helpers/get_last_metric');

var _get_last_metric2 = _interopRequireDefault(_get_last_metric);

var _map_bucket = require('../../helpers/map_bucket');

var _map_bucket2 = _interopRequireDefault(_map_bucket);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function stdMetric(bucket, panel, series) {
  return next => results => {
    const metric = (0, _get_last_metric2.default)(series);
    if (metric.type === 'std_deviation' && metric.mode === 'band') {
      return next(results);
    }
    if (metric.type === 'percentile') {
      return next(results);
    }
    if (/_bucket$/.test(metric.type)) return next(results);

    const fakeResp = { aggregations: bucket };
    (0, _get_splits2.default)(fakeResp, panel, series).forEach(split => {
      const data = split.timeseries.buckets.map((0, _map_bucket2.default)(metric));
      results.push({
        id: split.id,
        label: split.label,
        data
      });
    });

    return next(results);
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
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = percentile;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _get_agg_value = require('../../helpers/get_agg_value');

var _get_agg_value2 = _interopRequireDefault(_get_agg_value);

var _get_splits = require('../../helpers/get_splits');

var _get_splits2 = _interopRequireDefault(_get_splits);

var _get_last_metric = require('../../helpers/get_last_metric');

var _get_last_metric2 = _interopRequireDefault(_get_last_metric);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

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

function percentile(resp, panel, series) {
  return next => results => {
    const metric = (0, _get_last_metric2.default)(series);
    if (metric.type !== 'percentile') return next(results);

    (0, _get_splits2.default)(resp, panel, series).forEach(split => {
      const label = split.label + ` (${series.value})`;
      const data = split.timeseries.buckets.map(bucket => {
        const m = _lodash2.default.assign({}, metric, { percent: series.value });
        return [bucket.key, (0, _get_agg_value2.default)(bucket, m)];
      });
      results.push({
        id: `${percentile.id}:${split.id}`,
        label,
        data
      });
    });
    return next(results);
  };
}
module.exports = exports['default'];
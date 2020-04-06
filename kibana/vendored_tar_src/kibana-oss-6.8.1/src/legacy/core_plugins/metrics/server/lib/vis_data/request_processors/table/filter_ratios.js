'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = ratios;

var _bucket_transform = require('../../helpers/bucket_transform');

var _bucket_transform2 = _interopRequireDefault(_bucket_transform);

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _calculate_agg_root = require('./calculate_agg_root');

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

/* eslint max-len:0 */
const filter = metric => metric.type === 'filter_ratio';
function ratios(req, panel) {
  return () => doc => {
    panel.series.forEach(column => {
      const aggRoot = (0, _calculate_agg_root.calculateAggRoot)(doc, column);
      if (column.metrics.some(filter)) {
        column.metrics.filter(filter).forEach(metric => {
          _lodash2.default.set(doc, `${aggRoot}.timeseries.aggs.${metric.id}-numerator.filter`, {
            query_string: { query: metric.numerator || '*', analyze_wildcard: true }
          });
          _lodash2.default.set(doc, `${aggRoot}.timeseries.aggs.${metric.id}-denominator.filter`, {
            query_string: { query: metric.denominator || '*', analyze_wildcard: true }
          });

          let numeratorPath = `${metric.id}-numerator>_count`;
          let denominatorPath = `${metric.id}-denominator>_count`;

          if (metric.metric_agg !== 'count' && _bucket_transform2.default[metric.metric_agg]) {
            const aggBody = {
              metric: _bucket_transform2.default[metric.metric_agg]({
                type: metric.metric_agg,
                field: metric.field
              })
            };
            _lodash2.default.set(doc, `${aggRoot}.timeseries.aggs.${metric.id}-numerator.aggs`, aggBody);
            _lodash2.default.set(doc, `${aggBody}.timeseries.aggs.${metric.id}-denominator.aggs`, aggBody);
            numeratorPath = `${metric.id}-numerator>metric`;
            denominatorPath = `${metric.id}-denominator>metric`;
          }

          _lodash2.default.set(doc, `${aggRoot}.timeseries.aggs.${metric.id}`, {
            bucket_script: {
              buckets_path: {
                numerator: numeratorPath,
                denominator: denominatorPath
              },
              script: 'params.numerator != null && params.denominator != null && params.denominator > 0 ? params.numerator / params.denominator : 0'
            }
          });
        });
      }
    });
    return doc;
  };
}
module.exports = exports['default'];
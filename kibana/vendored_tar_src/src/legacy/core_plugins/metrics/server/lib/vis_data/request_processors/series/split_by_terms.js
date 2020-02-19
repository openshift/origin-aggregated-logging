'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = splitByTerm;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _basic_aggs = require('../../../../../common/basic_aggs');

var _basic_aggs2 = _interopRequireDefault(_basic_aggs);

var _get_buckets_path = require('../../helpers/get_buckets_path');

var _get_buckets_path2 = _interopRequireDefault(_get_buckets_path);

var _bucket_transform = require('../../helpers/bucket_transform');

var _bucket_transform2 = _interopRequireDefault(_bucket_transform);

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

function splitByTerm(req, panel, series) {
  return next => doc => {
    if (series.split_mode === 'terms' && series.terms_field) {
      const direction = series.terms_direction || 'desc';
      _lodash2.default.set(doc, `aggs.${series.id}.terms.field`, series.terms_field);
      _lodash2.default.set(doc, `aggs.${series.id}.terms.size`, series.terms_size);
      const metric = series.metrics.find(item => item.id === series.terms_order_by);
      if (metric && metric.type !== 'count' && ~_basic_aggs2.default.indexOf(metric.type)) {
        const sortAggKey = `${series.terms_order_by}-SORT`;
        const fn = _bucket_transform2.default[metric.type];
        const bucketPath = (0, _get_buckets_path2.default)(series.terms_order_by, series.metrics).replace(series.terms_order_by, sortAggKey);
        _lodash2.default.set(doc, `aggs.${series.id}.terms.order`, { [bucketPath]: direction });
        _lodash2.default.set(doc, `aggs.${series.id}.aggs`, { [sortAggKey]: fn(metric) });
      } else if (['_term', '_count'].includes(series.terms_order_by)) {
        _lodash2.default.set(doc, `aggs.${series.id}.terms.order`, { [series.terms_order_by]: direction });
      } else {
        _lodash2.default.set(doc, `aggs.${series.id}.terms.order`, { _count: direction });
      }
    }
    return next(doc);
  };
}
module.exports = exports['default'];
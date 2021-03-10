'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.timeBucketsToPairs = timeBucketsToPairs;
exports.flattenBucket = flattenBucket;
exports.default = toSeriesList;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function timeBucketsToPairs(buckets) {
  const timestamps = _lodash2.default.pluck(buckets, 'key');
  const series = {};
  _lodash2.default.each(buckets, function (bucket) {
    _lodash2.default.forOwn(bucket, function (val, key) {
      if (_lodash2.default.isPlainObject(val)) {
        if (val.values) {
          _lodash2.default.forOwn(val.values, function (bucketValue, bucketKey) {
            const k = key + ':' + bucketKey;
            const v = isNaN(bucketValue) ? NaN : bucketValue;
            series[k] = series[k] || [];
            series[k].push(v);
          });
        } else {
          series[key] = series[key] || [];
          series[key].push(val.value);
        }
      }
    });
  });

  return _lodash2.default.mapValues(series, function (values) {
    return _lodash2.default.zip(timestamps, values);
  });
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

function flattenBucket(bucket, splitKey, path, result) {
  result = result || {};
  path = path || [];
  _lodash2.default.forOwn(bucket, function (val, key) {
    if (!_lodash2.default.isPlainObject(val)) return;
    if (_lodash2.default.get(val, 'meta.type') === 'split') {
      _lodash2.default.each(val.buckets, function (bucket, bucketKey) {
        if (bucket.key == null) bucket.key = bucketKey; // For handling "keyed" response formats, e.g., filters agg
        flattenBucket(bucket, bucket.key, path.concat([key + ':' + bucket.key]), result);
      });
    } else if (_lodash2.default.get(val, 'meta.type') === 'time_buckets') {
      const metrics = timeBucketsToPairs(val.buckets);
      _lodash2.default.each(metrics, function (pairs, metricName) {
        result[path.concat([metricName]).join(' > ')] = {
          data: pairs,
          splitKey: splitKey
        };
      });
    }
  });
  return result;
}

function toSeriesList(aggs, config) {
  return _lodash2.default.map(flattenBucket(aggs), function (metrics, name) {
    return {
      data: metrics.data,
      type: 'series',
      fit: config.fit,
      label: name,
      split: metrics.splitKey
    };
  });
}
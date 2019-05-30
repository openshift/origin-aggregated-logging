'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

exports.mathAgg = mathAgg;

var _lodash = require('lodash');

var _get_default_decoration = require('../../helpers/get_default_decoration');

var _get_default_decoration2 = _interopRequireDefault(_get_default_decoration);

var _get_sibling_agg_value = require('../../helpers/get_sibling_agg_value');

var _get_sibling_agg_value2 = _interopRequireDefault(_get_sibling_agg_value);

var _get_splits = require('../../helpers/get_splits');

var _get_splits2 = _interopRequireDefault(_get_splits);

var _map_bucket = require('../../helpers/map_bucket');

var _map_bucket2 = _interopRequireDefault(_map_bucket);

var _tinymath = require('tinymath');

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

const percentileValueMatch = /\[([0-9\.]+)\]$/;
function mathAgg(resp, panel, series) {
  return next => results => {
    const mathMetric = (0, _lodash.last)(series.metrics);
    if (mathMetric.type !== 'math') return next(results);
    // Filter the results down to only the ones that match the series.id. Sometimes
    // there will be data from other series mixed in.
    results = results.filter(s => {
      if (s.id.split(/:/)[0] === series.id) {
        return false;
      }
      return true;
    });
    const decoration = (0, _get_default_decoration2.default)(series);
    const splits = (0, _get_splits2.default)(resp, panel, series);
    const mathSeries = splits.map(split => {
      if (mathMetric.variables.length) {
        // Gather the data for the splits. The data will either be a sibling agg or
        // a standard metric/pipeline agg
        const splitData = mathMetric.variables.reduce((acc, v) => {
          const metric = series.metrics.find(m => (0, _lodash.startsWith)(v.field, m.id));
          if (!metric) return acc;
          if (/_bucket$/.test(metric.type)) {
            acc[v.name] = split.timeseries.buckets.map(bucket => {
              return [bucket.key, (0, _get_sibling_agg_value2.default)(split, metric)];
            });
          } else {
            const percentileMatch = v.field.match(percentileValueMatch);
            const m = percentileMatch ? _extends({}, metric, { percent: percentileMatch[1] }) : _extends({}, metric);
            acc[v.name] = split.timeseries.buckets.map((0, _map_bucket2.default)(m));
          }
          return acc;
        }, {});
        // Create an params._all so the users can access the entire series of data
        // in the Math.js equation
        const all = Object.keys(splitData).reduce((acc, key) => {
          acc[key] = {
            values: splitData[key].map(x => x[1]),
            timestamps: splitData[key].map(x => x[0])
          };
          return acc;
        }, {});
        // Get the first var and check that it shows up in the split data otherwise
        // we need to return an empty array for the data since we can't operate
        // without the first variable
        const firstVar = (0, _lodash.first)(mathMetric.variables);
        if (!splitData[firstVar.name]) {
          return _extends({
            id: split.id,
            label: split.label,
            color: split.color,
            data: []
          }, decoration);
        }
        // Use the first var to collect all the timestamps
        const timestamps = splitData[firstVar.name].map(r => (0, _lodash.first)(r));
        // Map the timestamps to actual data
        const data = timestamps.map((ts, index) => {
          const params = mathMetric.variables.reduce((acc, v) => {
            acc[v.name] = (0, _lodash.last)(splitData[v.name].find(row => row[0] === ts));
            return acc;
          }, {});
          // If some of the values are null, return the timestamp and null, this is
          // a safety check for the user
          const someNull = (0, _lodash.values)(params).some(v => v == null);
          if (someNull) return [ts, null];
          // calculate the result based on the user's script and return the value
          const result = (0, _tinymath.evaluate)(mathMetric.script, {
            params: _extends({}, params, {
              _index: index,
              _timestamp: ts,
              _all: all,
              _interval: split.meta.bucketSize * 1000
            })
          });
          // if the result is an object (usually when the user is working with maps and functions) flatten the results and return the last value.
          if (typeof result === 'object') {
            return [ts, (0, _lodash.last)((0, _lodash.flatten)(result.valueOf()))];
          }
          return [ts, result];
        });
        return _extends({
          id: split.id,
          label: split.label,
          color: split.color,
          data
        }, decoration);
      }
    });
    return next(results.concat(mathSeries));
  };
}
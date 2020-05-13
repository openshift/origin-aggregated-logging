'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; /*
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

exports.default = getSplits;

var _color = require('color');

var _color2 = _interopRequireDefault(_color);

var _calculate_label = require('../../../../common/calculate_label');

var _calculate_label2 = _interopRequireDefault(_calculate_label);

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _get_last_metric = require('./get_last_metric');

var _get_last_metric2 = _interopRequireDefault(_get_last_metric);

var _get_split_colors = require('./get_split_colors');

var _get_split_colors2 = _interopRequireDefault(_get_split_colors);

var _format_key = require('./format_key');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function getSplits(resp, panel, series) {
  const meta = _lodash2.default.get(resp, `aggregations.${series.id}.meta`);
  const color = new _color2.default(series.color);
  const metric = (0, _get_last_metric2.default)(series);
  if (_lodash2.default.has(resp, `aggregations.${series.id}.buckets`)) {
    const buckets = _lodash2.default.get(resp, `aggregations.${series.id}.buckets`);
    if (Array.isArray(buckets)) {
      const size = buckets.length;
      const colors = (0, _get_split_colors2.default)(series.color, size, series.split_color_mode);
      return buckets.map(bucket => {
        bucket.id = `${series.id}:${bucket.key}`;
        bucket.label = (0, _format_key.formatKey)(bucket.key, series);
        bucket.color = panel.type === 'top_n' ? color.string() : colors.shift();
        bucket.meta = meta;
        return bucket;
      });
    }

    if (series.split_mode === 'filters' && _lodash2.default.isPlainObject(buckets)) {
      return series.split_filters.map(filter => {
        const bucket = _lodash2.default.get(resp, `aggregations.${series.id}.buckets.${filter.id}`);
        bucket.id = `${series.id}:${filter.id}`;
        bucket.key = filter.id;
        bucket.color = filter.color;
        bucket.label = filter.label || filter.filter || '*';
        bucket.meta = meta;
        return bucket;
      });
    }
  }

  const timeseries = _lodash2.default.get(resp, `aggregations.${series.id}.timeseries`);
  const mergeObj = {
    timeseries
  };
  series.metrics.filter(m => /_bucket/.test(m.type)).forEach(m => {
    mergeObj[m.id] = _lodash2.default.get(resp, `aggregations.${series.id}.${m.id}`);
  });
  return [_extends({
    id: series.id,
    label: series.label || (0, _calculate_label2.default)(metric, series.metrics),
    color: color.string()
  }, mergeObj, {
    meta
  })];
}
module.exports = exports['default'];
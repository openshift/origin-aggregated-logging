'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = calculateLabel;

var _lodash = require('lodash');

var _agg_lookup = require('./agg_lookup');

var _agg_lookup2 = _interopRequireDefault(_agg_lookup);

var _i18n = require('@kbn/i18n');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const paths = ['cumulative_sum', 'derivative', 'moving_average', 'avg_bucket', 'sum_bucket', 'min_bucket', 'max_bucket', 'std_deviation_bucket', 'variance_bucket', 'sum_of_squares_bucket', 'serial_diff', 'positive_only']; /*
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

function calculateLabel(metric, metrics) {
  if (!metric) return _i18n.i18n.translate('tsvb.calculateLabel.unknownLabel', { defaultMessage: 'Unknown' });
  if (metric.alias) return metric.alias;

  if (metric.type === 'count') return _i18n.i18n.translate('tsvb.calculateLabel.countLabel', { defaultMessage: 'Count' });
  if (metric.type === 'calculation') {
    return _i18n.i18n.translate('tsvb.calculateLabel.bucketScriptsLabel', { defaultMessage: 'Bucket Script' });
  }
  if (metric.type === 'math') return _i18n.i18n.translate('tsvb.calculateLabel.mathLabel', { defaultMessage: 'Math' });
  if (metric.type === 'series_agg') {
    return _i18n.i18n.translate('tsvb.calculateLabel.seriesAggLabel', { defaultMessage: 'Series Agg ({metricFunction})', values: { metricFunction: metric.function } });
  }
  if (metric.type === 'filter_ratio') return _i18n.i18n.translate('tsvb.calculateLabel.filterRatioLabel', { defaultMessage: 'Filter Ratio' });
  if (metric.type === 'static') {
    return _i18n.i18n.translate('tsvb.calculateLabel.staticValueLabel', { defaultMessage: 'Static Value of {metricValue}', values: { metricValue: metric.value } });
  }

  if (metric.type === 'percentile_rank') {
    return _i18n.i18n.translate('tsvb.calculateLabel.percentileRankLabel', {
      defaultMessage: '{lookupMetricType} ({metricValue}) of {metricField}',
      values: { lookupMetricType: _agg_lookup2.default[metric.type], metricValue: metric.value, metricField: metric.field }
    });
  }

  if ((0, _lodash.includes)(paths, metric.type)) {
    const targetMetric = metrics.find(m => (0, _lodash.startsWith)(metric.field, m.id));
    const targetLabel = calculateLabel(targetMetric, metrics);
    // For percentiles we need to parse the field id to extract the percentile
    // the user configured in the percentile aggregation and specified in the
    // submetric they selected. This applies only to pipeline aggs.
    if (targetMetric && targetMetric.type === 'percentile') {
      const percentileValueMatch = /\[([0-9\.]+)\]$/;
      const matches = metric.field.match(percentileValueMatch);
      if (matches) {
        return _i18n.i18n.translate('tsvb.calculateLabel.lookupMetricTypeOfTargetWithAdditionalLabel', {
          defaultMessage: '{lookupMetricType} of {targetLabel} ({additionalLabel})',
          values: { lookupMetricType: _agg_lookup2.default[metric.type], targetLabel, additionalLabel: matches[1] }
        });
      }
    }
    return _i18n.i18n.translate('tsvb.calculateLabel.lookupMetricTypeOfTargetLabel', {
      defaultMessage: '{lookupMetricType} of {targetLabel}',
      values: { lookupMetricType: _agg_lookup2.default[metric.type], targetLabel }
    });
  }

  return _i18n.i18n.translate('tsvb.calculateLabel.lookupMetricTypeOfMetricFieldRankLabel', {
    defaultMessage: '{lookupMetricType} of {metricField}',
    values: { lookupMetricType: _agg_lookup2.default[metric.type], metricField: metric.field }
  });
}
module.exports = exports['default'];
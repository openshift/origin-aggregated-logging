'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.isBasicAgg = isBasicAgg;
exports.createOptions = createOptions;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _i18n = require('@kbn/i18n');

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

const lookup = {
  count: _i18n.i18n.translate('tsvb.aggLookup.countLabel', { defaultMessage: 'Count' }),
  calculation: _i18n.i18n.translate('tsvb.aggLookup.calculationLabel', { defaultMessage: 'Calculation' }),
  std_deviation: _i18n.i18n.translate('tsvb.aggLookup.deviationLabel', { defaultMessage: 'Std. Deviation' }),
  variance: _i18n.i18n.translate('tsvb.aggLookup.varianceLabel', { defaultMessage: 'Variance' }),
  sum_of_squares: _i18n.i18n.translate('tsvb.aggLookup.sumOfSqLabel', { defaultMessage: 'Sum of Sq.' }),
  avg: _i18n.i18n.translate('tsvb.aggLookup.averageLabel', { defaultMessage: 'Average' }),
  max: _i18n.i18n.translate('tsvb.aggLookup.maxLabel', { defaultMessage: 'Max' }),
  min: _i18n.i18n.translate('tsvb.aggLookup.minLabel', { defaultMessage: 'Min' }),
  sum: _i18n.i18n.translate('tsvb.aggLookup.sumLabel', { defaultMessage: 'Sum' }),
  percentile: _i18n.i18n.translate('tsvb.aggLookup.percentileLabel', { defaultMessage: 'Percentile' }),
  percentile_rank: _i18n.i18n.translate('tsvb.aggLookup.percentileRankLabel', { defaultMessage: 'Percentile Rank' }),
  cardinality: _i18n.i18n.translate('tsvb.aggLookup.cardinalityLabel', { defaultMessage: 'Cardinality' }),
  value_count: _i18n.i18n.translate('tsvb.aggLookup.valueCountLabel', { defaultMessage: 'Value Count' }),
  derivative: _i18n.i18n.translate('tsvb.aggLookup.derivativeLabel', { defaultMessage: 'Derivative' }),
  cumulative_sum: _i18n.i18n.translate('tsvb.aggLookup.cumulativeSumLabel', { defaultMessage: 'Cumulative Sum' }),
  moving_average: _i18n.i18n.translate('tsvb.aggLookup.movingAverageLabel', { defaultMessage: 'Moving Average' }),
  avg_bucket: _i18n.i18n.translate('tsvb.aggLookup.overallAverageLabel', { defaultMessage: 'Overall Average' }),
  min_bucket: _i18n.i18n.translate('tsvb.aggLookup.overallMinLabel', { defaultMessage: 'Overall Min' }),
  max_bucket: _i18n.i18n.translate('tsvb.aggLookup.overallMaxLabel', { defaultMessage: 'Overall Max' }),
  sum_bucket: _i18n.i18n.translate('tsvb.aggLookup.overallSumLabel', { defaultMessage: 'Overall Sum' }),
  variance_bucket: _i18n.i18n.translate('tsvb.aggLookup.overallVarianceLabel', { defaultMessage: 'Overall Variance' }),
  sum_of_squares_bucket: _i18n.i18n.translate('tsvb.aggLookup.overallSumOfSqLabel', { defaultMessage: 'Overall Sum of Sq.' }),
  std_deviation_bucket: _i18n.i18n.translate('tsvb.aggLookup.overallStdDeviationLabel', { defaultMessage: 'Overall Std. Deviation' }),
  series_agg: _i18n.i18n.translate('tsvb.aggLookup.seriesAggLabel', { defaultMessage: 'Series Agg' }),
  math: _i18n.i18n.translate('tsvb.aggLookup.mathLabel', { defaultMessage: 'Math' }),
  serial_diff: _i18n.i18n.translate('tsvb.aggLookup.serialDifferenceLabel', { defaultMessage: 'Serial Difference' }),
  filter_ratio: _i18n.i18n.translate('tsvb.aggLookup.filterRatioLabel', { defaultMessage: 'Filter Ratio' }),
  positive_only: _i18n.i18n.translate('tsvb.aggLookup.positiveOnlyLabel', { defaultMessage: 'Positive Only' }),
  static: _i18n.i18n.translate('tsvb.aggLookup.staticValueLabel', { defaultMessage: 'Static Value' }),
  top_hit: _i18n.i18n.translate('tsvb.aggLookup.topHitLabel', { defaultMessage: 'Top Hit' })
};

const pipeline = ['calculation', 'derivative', 'cumulative_sum', 'moving_average', 'avg_bucket', 'min_bucket', 'max_bucket', 'sum_bucket', 'variance_bucket', 'sum_of_squares_bucket', 'std_deviation_bucket', 'series_agg', 'math', 'serial_diff', 'positive_only'];

const byType = {
  _all: lookup,
  pipeline: pipeline,
  basic: _lodash2.default.omit(lookup, pipeline),
  metrics: _lodash2.default.pick(lookup, ['count', 'avg', 'min', 'max', 'sum', 'cardinality', 'value_count'])
};

function isBasicAgg(item) {
  return _lodash2.default.includes(Object.keys(byType.basic), item.type);
}

function createOptions(type = '_all', siblings = []) {
  let aggs = byType[type];
  if (!aggs) aggs = byType._all;
  let enablePipelines = siblings.some(isBasicAgg);
  if (siblings.length <= 1) enablePipelines = false;
  return (0, _lodash2.default)(aggs).map((label, value) => {
    const disabled = _lodash2.default.includes(pipeline, value) ? !enablePipelines : false;
    return {
      label: disabled ? _i18n.i18n.translate('tsvb.aggLookup.addPipelineAggDescription', {
        defaultMessage: '{label} (use the "+" button to add this pipeline agg)',
        values: { label }
      }) : label,
      value,
      disabled
    };
  }).value();
}

exports.default = lookup;
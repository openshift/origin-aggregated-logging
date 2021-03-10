'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _percentile = require('./percentile');

var _percentile2 = _interopRequireDefault(_percentile);

var _series_agg = require('./series_agg');

var _series_agg2 = _interopRequireDefault(_series_agg);

var _std_deviation_bands = require('./std_deviation_bands');

var _std_deviation_bands2 = _interopRequireDefault(_std_deviation_bands);

var _std_deviation_sibling = require('./std_deviation_sibling');

var _std_deviation_sibling2 = _interopRequireDefault(_std_deviation_sibling);

var _std_metric = require('./std_metric');

var _std_metric2 = _interopRequireDefault(_std_metric);

var _std_sibling = require('./std_sibling');

var _std_sibling2 = _interopRequireDefault(_std_sibling);

var _time_shift = require('./time_shift');

var _time_shift2 = _interopRequireDefault(_time_shift);

var _drop_last_bucket = require('./drop_last_bucket');

var _math = require('./math');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = [_percentile2.default, _std_deviation_bands2.default, _std_deviation_sibling2.default, _std_metric2.default, _std_sibling2.default, _math.mathAgg, _series_agg2.default, _time_shift2.default, _drop_last_bucket.dropLastBucket]; /*
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
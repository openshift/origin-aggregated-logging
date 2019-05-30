'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _std_metric = require('./std_metric');

var _std_metric2 = _interopRequireDefault(_std_metric);

var _std_sibling = require('./std_sibling');

var _std_sibling2 = _interopRequireDefault(_std_sibling);

var _series_agg = require('./series_agg');

var _series_agg2 = _interopRequireDefault(_series_agg);

var _math = require('./math');

var _drop_last_bucket = require('./drop_last_bucket');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = [
// percentile,
_std_metric2.default, _std_sibling2.default, _math.math, _series_agg2.default, _drop_last_bucket.dropLastBucketFn]; /*
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

// import percentile from './percentile';

module.exports = exports['default'];
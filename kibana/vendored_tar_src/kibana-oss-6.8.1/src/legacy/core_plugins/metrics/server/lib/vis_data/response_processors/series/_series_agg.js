'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function mean(values) {
  return _lodash2.default.sum(values) / values.length;
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

const basic = fnName => targetSeries => {
  const data = [];
  _lodash2.default.zip(...targetSeries).forEach(row => {
    const key = row[0][0];
    const values = row.map(r => r && r[1] || 0);
    const fn = _lodash2.default[fnName] || (() => null);
    data.push([key, fn(values)]);
  });
  return [data];
};

const overall = fnName => targetSeries => {
  const fn = _lodash2.default[fnName];
  const keys = [];
  const values = [];
  _lodash2.default.zip(...targetSeries).forEach(row => {
    keys.push(row[0][0]);
    values.push(fn(row.map(r => r && r[1] || 0)));
  });
  return [keys.map(k => [k, fn(values)])];
};

exports.default = {
  sum: basic('sum'),
  max: basic('max'),
  min: basic('min'),
  mean(targetSeries) {
    const data = [];
    _lodash2.default.zip(...targetSeries).forEach(row => {
      const key = row[0][0];
      const values = row.map(r => r && r[1] || 0);
      data.push([key, mean(values)]);
    });
    return [data];
  },

  overall_max: overall('max'),
  overall_min: overall('min'),
  overall_sum: overall('sum'),

  overall_avg(targetSeries) {
    const fn = mean;
    const keys = [];
    const values = [];
    _lodash2.default.zip(...targetSeries).forEach(row => {
      keys.push(row[0][0]);
      values.push(_lodash2.default.sum(row.map(r => r && r[1] || 0)));
    });
    return [keys.map(k => [k, fn(values)])];
  },

  cumulative_sum(targetSeries) {
    const data = [];
    let sum = 0;
    _lodash2.default.zip(...targetSeries).forEach(row => {
      const key = row[0][0];
      sum += _lodash2.default.sum(row.map(r => r && r[1] || 0));
      data.push([key, sum]);
    });
    return [data];
  }

};
module.exports = exports['default'];
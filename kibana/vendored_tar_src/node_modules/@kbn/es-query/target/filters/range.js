'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.buildRangeFilter = buildRangeFilter;
exports.getRangeScript = getRangeScript;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var OPERANDS_IN_RANGE = 2; /*
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

var operators = {
  gt: '>',
  gte: '>=',
  lte: '<=',
  lt: '<'
};
var comparators = {
  gt: 'boolean gt(Supplier s, def v) {return s.get() > v}',
  gte: 'boolean gte(Supplier s, def v) {return s.get() >= v}',
  lte: 'boolean lte(Supplier s, def v) {return s.get() <= v}',
  lt: 'boolean lt(Supplier s, def v) {return s.get() < v}'
};

function formatValue(field, params) {
  return _lodash2.default.map(params, function (val, key) {
    return operators[key] + format(field, val);
  }).join(' ');
}

function buildRangeFilter(field, params, indexPattern, formattedValue) {
  var filter = { meta: { index: indexPattern.id } };
  if (formattedValue) filter.meta.formattedValue = formattedValue;

  params = _lodash2.default.mapValues(params, function (value) {
    return field.type === 'number' ? parseFloat(value) : value;
  });

  if ('gte' in params && 'gt' in params) throw new Error('gte and gt are mutually exclusive');
  if ('lte' in params && 'lt' in params) throw new Error('lte and lt are mutually exclusive');

  var totalInfinite = ['gt', 'lt'].reduce(function (totalInfinite, op) {
    var key = op in params ? op : op + 'e';
    var isInfinite = Math.abs(params[key]) === Infinity;

    if (isInfinite) {
      totalInfinite++;
      delete params[key];
    }

    return totalInfinite;
  }, 0);

  if (totalInfinite === OPERANDS_IN_RANGE) {
    filter.match_all = {};
    filter.meta.field = field.name;
  } else if (field.scripted) {
    filter.script = getRangeScript(field, params);
    filter.script.script.params.value = formatValue(field, filter.script.script.params);

    filter.meta.field = field.name;
  } else {
    filter.range = {};
    filter.range[field.name] = params;
  }

  return filter;
}

function getRangeScript(field, params) {
  var knownParams = _lodash2.default.pick(params, function (val, key) {
    return key in operators;
  });
  var script = _lodash2.default.map(knownParams, function (val, key) {
    return '(' + field.script + ')' + operators[key] + key;
  }).join(' && ');

  // We must wrap painless scripts in a lambda in case they're more than a simple expression
  if (field.lang === 'painless') {
    var currentComparators = _lodash2.default.reduce(knownParams, function (acc, val, key) {
      return acc.concat(comparators[key]);
    }, []).join(' ');

    var comparisons = _lodash2.default.map(knownParams, function (val, key) {
      return key + '(() -> { ' + field.script + ' }, params.' + key + ')';
    }).join(' && ');

    script = '' + currentComparators + comparisons;
  }

  return {
    script: {
      source: script,
      params: knownParams,
      lang: field.lang
    }
  };
}

function format(field, value) {
  return field && field.format && field.format.convert ? field.format.convert(value) : value;
}
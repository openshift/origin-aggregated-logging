'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _i18n = require('@kbn/i18n');

var _alter = require('../../lib/alter.js');

var _alter2 = _interopRequireDefault(_alter);

var _chainable = require('../../lib/classes/chainable');

var _chainable2 = _interopRequireDefault(_chainable);

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

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

const functions = {
  avg: require('./avg'),
  cardinality: require('./cardinality'),
  min: require('./min'),
  max: require('./max'),
  last: require('./last'),
  first: require('./first'),
  sum: require('./sum')
};

exports.default = new _chainable2.default('aggregate', {
  args: [{
    name: 'inputSeries',
    types: ['seriesList']
  }, {
    name: 'function',
    types: ['string'],
    help: _i18n.i18n.translate('timelion.help.functions.aggregate.args.functionHelpText', {
      defaultMessage: 'One of {functions}',
      values: {
        functions: _lodash2.default.keys(functions).join(', ')
      }
    })
  }],
  help: _i18n.i18n.translate('timelion.help.functions.aggregateHelpText', {
    defaultMessage: 'Creates a static line based on result of processing all points in the series. Available functions: {functions}',
    values: {
      functions: _lodash2.default.keys(functions).join(', ')
    }
  }),
  fn: function aggregateFn(args) {
    const fn = functions[args.byName.function];
    if (!fn) throw new Error('.aggregate() function must be one of: ' + _lodash2.default.keys(functions).join(', '));

    return (0, _alter2.default)(args, function (eachSeries) {
      const times = _lodash2.default.map(eachSeries.data, 0);
      const values = _lodash2.default.map(eachSeries.data, 1);

      eachSeries.data = _lodash2.default.zip(times, _lodash2.default.fill(values, fn(values)));
      return eachSeries;
    });
  }
});
module.exports = exports['default'];
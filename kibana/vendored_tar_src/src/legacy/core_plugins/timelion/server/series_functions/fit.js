'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _i18n = require('@kbn/i18n');

var _alter = require('../lib/alter.js');

var _alter2 = _interopRequireDefault(_alter);

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _chainable = require('../lib/classes/chainable');

var _chainable2 = _interopRequireDefault(_chainable);

var _load_functions = require('../lib/load_functions.js');

var _load_functions2 = _interopRequireDefault(_load_functions);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const fitFunctions = (0, _load_functions2.default)('fit_functions'); /*
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

exports.default = new _chainable2.default('fit', {
  args: [{
    name: 'inputSeries',
    types: ['seriesList']
  }, {
    name: 'mode',
    types: ['string'],
    help: _i18n.i18n.translate('timelion.help.functions.fit.args.modeHelpText', {
      defaultMessage: 'The algorithm to use for fitting the series to the target. One of: {fitFunctions}',
      values: {
        fitFunctions: _lodash2.default.keys(fitFunctions).join(', ')
      }
    }),
    suggestions: _lodash2.default.keys(fitFunctions).map(key => {
      return { name: key };
    })
  }],
  help: _i18n.i18n.translate('timelion.help.functions.fitHelpText', {
    defaultMessage: 'Fills null values using a defined fit function'
  }),
  fn: function absFn(args) {
    return (0, _alter2.default)(args, function (eachSeries, mode) {

      const noNulls = eachSeries.data.filter(item => item[1] === 0 || item[1]);

      if (noNulls.length === 0) {
        return eachSeries;
      }

      eachSeries.data = fitFunctions[mode](noNulls, eachSeries.data);
      return eachSeries;
    });
  }
});
module.exports = exports['default'];
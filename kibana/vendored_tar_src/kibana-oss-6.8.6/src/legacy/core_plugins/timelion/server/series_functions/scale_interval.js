'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _i18n = require('@kbn/i18n');

var _alter = require('../lib/alter.js');

var _alter2 = _interopRequireDefault(_alter);

var _to_milliseconds = require('../lib/to_milliseconds.js');

var _to_milliseconds2 = _interopRequireDefault(_to_milliseconds);

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _chainable = require('../lib/classes/chainable');

var _chainable2 = _interopRequireDefault(_chainable);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = new _chainable2.default('scale_interval', {
  args: [{
    name: 'inputSeries',
    types: ['seriesList']
  }, {
    name: 'interval',
    types: ['string'],
    help: _i18n.i18n.translate('timelion.help.functions.scaleInterval.args.intervalHelpText', {
      defaultMessage: 'The new interval in date math notation, e.g., 1s for 1 second. 1m, 5m, 1M, 1w, 1y, etc.'
    })
  }],
  help: _i18n.i18n.translate('timelion.help.functions.scaleIntervalHelpText', {
    defaultMessage: 'Changes scales a value (usually a sum or a count) to a new interval. For example, as a per-second rate'
  }),
  fn: function scaleIntervalFn(args, tlConfig) {
    const currentInterval = (0, _to_milliseconds2.default)(tlConfig.time.interval);
    const scaleInterval = (0, _to_milliseconds2.default)(args.byName.interval);

    return (0, _alter2.default)(args, function (eachSeries) {
      const data = _lodash2.default.map(eachSeries.data, function (point) {
        return [point[0], point[1] / currentInterval * scaleInterval];
      });
      eachSeries.data = data;
      return eachSeries;
    });
  }
}); /*
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
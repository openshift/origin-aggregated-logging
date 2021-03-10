'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _i18n = require('@kbn/i18n');

var _load_functions = require('../load_functions.js');

var _load_functions2 = _interopRequireDefault(_load_functions);

var _timelion_function = require('./timelion_function');

var _timelion_function2 = _interopRequireDefault(_timelion_function);

var _offset_time = require('../offset_time');

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

const fitFunctions = (0, _load_functions2.default)('fit_functions');


function offsetSeries(response, offset) {
  if (offset) {
    response = _lodash2.default.map(response, function (point) {
      return [(0, _offset_time.offsetTime)(point[0], offset, true), point[1]];
    });
  }
  return response;
}

class Datasource extends _timelion_function2.default {
  constructor(name, config) {

    // Additional arguments that every dataSource take
    config.args.push({
      name: 'offset',
      types: ['string', 'null'],
      help: _i18n.i18n.translate('timelion.help.functions.common.args.offsetHelpText', {
        defaultMessage: 'Offset the series retrieval by a date expression, e.g., -1M to make events from ' + 'one month ago appear as if they are happening now. Offset the series relative to the charts ' + 'overall time range, by using the value "timerange", e.g. "timerange:-2" will specify an offset ' + 'that is twice the overall chart time range to the past.'
      })
    });

    config.args.push({
      name: 'fit',
      types: ['string', 'null'],
      help: _i18n.i18n.translate('timelion.help.functions.common.args.fitHelpText', {
        defaultMessage: 'Algorithm to use for fitting series to the target time span and interval. Available: {fitFunctions}',
        values: {
          fitFunctions: _lodash2.default.keys(fitFunctions).join(', ')
        }
      })
    });

    // Wrap the original function so we can modify inputs/outputs with offset & fit
    const originalFunction = config.fn;
    config.fn = function (args, tlConfig) {
      const config = _lodash2.default.clone(tlConfig);
      let offset = args.byName.offset;
      if (offset) {
        offset = (0, _offset_time.preprocessOffset)(offset, tlConfig.time.from, tlConfig.time.to);
        config.time = _lodash2.default.cloneDeep(tlConfig.time);
        config.time.from = (0, _offset_time.offsetTime)(config.time.from, offset);
        config.time.to = (0, _offset_time.offsetTime)(config.time.to, offset);
      }

      return Promise.resolve(originalFunction(args, config)).then(function (seriesList) {
        seriesList.list = _lodash2.default.map(seriesList.list, function (series) {
          if (series.data.length === 0) throw new Error(name + '() returned no results');
          series.data = offsetSeries(series.data, offset);
          series.fit = args.byName.fit || series.fit || 'nearest';
          return series;
        });
        return seriesList;
      });
    };

    super(name, config);

    // You  need to call timelionFn if calling up a datasource from another datasource,
    // otherwise teh series will end up being offset twice.
    this.timelionFn = originalFunction;
    this.datasource = true;
    this.cacheKey = function (item) {
      return item.text;
    };
    Object.freeze(this);
  }

}
exports.default = Datasource;
module.exports = exports['default'];
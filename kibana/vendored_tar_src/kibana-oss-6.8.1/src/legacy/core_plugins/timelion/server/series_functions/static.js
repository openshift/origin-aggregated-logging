'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _i18n = require('@kbn/i18n');

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _datasource = require('../lib/classes/datasource');

var _datasource2 = _interopRequireDefault(_datasource);

var _bluebird = require('bluebird');

var _bluebird2 = _interopRequireDefault(_bluebird);

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

exports.default = new _datasource2.default('static', {
  aliases: ['value'],
  args: [{
    name: 'value', // _test-data.users.*.data
    types: ['number', 'string'],
    help: _i18n.i18n.translate('timelion.help.functions.static.args.valueHelpText', {
      defaultMessage: 'The single value to to display, you can also pass several values and I will interpolate them evenly across your time range.'
    })
  }, {
    name: 'label',
    types: ['string', 'null'],
    help: _i18n.i18n.translate('timelion.help.functions.static.args.labelHelpText', {
      defaultMessage: 'A quick way to set the label for the series. You could also use the .label() function'
    })
  }],
  help: _i18n.i18n.translate('timelion.help.functions.staticHelpText', {
    defaultMessage: 'Draws a single value across the chart'
  }),
  fn: function staticFn(args, tlConfig) {

    let data;
    const target = tlConfig.getTargetSeries();
    if (typeof args.byName.value === 'string') {
      const points = args.byName.value.split(':');
      const begin = _lodash2.default.first(target)[0];
      const end = _lodash2.default.last(target)[0];
      const step = (end - begin) / (points.length - 1);
      data = _lodash2.default.map(points, function (point, i) {
        return [begin + i * step, parseFloat(point)];
      });
    } else {
      data = _lodash2.default.map(target, function (bucket) {
        return [bucket[0], args.byName.value];
      });
    }

    return _bluebird2.default.resolve({
      type: 'seriesList',
      list: [{
        data: data,
        type: 'series',
        label: args.byName.label == null ? String(args.byName.value) : args.byName.label,
        fit: args.byName.fit || 'average'
      }]
    });
  }
});
module.exports = exports['default'];
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _i18n = require('@kbn/i18n');

var _alter = require('../lib/alter.js');

var _alter2 = _interopRequireDefault(_alter);

var _chainable = require('../lib/classes/chainable');

var _chainable2 = _interopRequireDefault(_chainable);

var _lib = require('../../common/lib');

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

exports.default = new _chainable2.default('legend', {
  args: [{
    name: 'inputSeries',
    types: ['seriesList']
  }, {
    name: 'position',
    types: ['string', 'boolean', 'null'],
    help: _i18n.i18n.translate('timelion.help.functions.legend.args.positionHelpText', {
      defaultMessage: 'Corner to place the legend in: nw, ne, se, or sw. You can also pass false to disable the legend',
      description: '"nw", "ne", "se", "sw" and "false" are keywords and must not be translated.'
    }),
    suggestions: [{
      name: 'false',
      help: _i18n.i18n.translate('timelion.help.functions.legend.args.position.suggestions.falseHelpText', {
        defaultMessage: 'disable legend'
      })
    }, {
      name: 'nw',
      help: _i18n.i18n.translate('timelion.help.functions.legend.args.position.suggestions.nwHelpText', {
        defaultMessage: 'place legend in north west corner'
      })
    }, {
      name: 'ne',
      help: _i18n.i18n.translate('timelion.help.functions.legend.args.position.suggestions.neHelpText', {
        defaultMessage: 'place legend in north east corner'
      })
    }, {
      name: 'se',
      help: _i18n.i18n.translate('timelion.help.functions.legend.args.position.suggestions.seHelpText', {
        defaultMessage: 'place legend in south east corner'
      })
    }, {
      name: 'sw',
      help: _i18n.i18n.translate('timelion.help.functions.legend.args.position.suggestions.swHelpText', {
        defaultMessage: 'place legend in south west corner'
      })
    }]
  }, {
    name: 'columns',
    types: ['number', 'null'],
    help: _i18n.i18n.translate('timelion.help.functions.legend.args.columnsHelpText', {
      defaultMessage: 'Number of columns to divide the legend into'
    })
  }, {
    name: 'showTime',
    types: ['boolean'],
    help: _i18n.i18n.translate('timelion.help.functions.legend.args.showTimeHelpText', {
      defaultMessage: 'Show time value in legend when hovering over graph. Default: true'
    })
  }, {
    name: 'timeFormat',
    types: ['string'],
    help: _i18n.i18n.translate('timelion.help.functions.legend.args.timeFormatHelpText', {
      defaultMessage: 'moment.js format pattern. Default: {defaultTimeFormat}',
      values: {
        defaultTimeFormat: _lib.DEFAULT_TIME_FORMAT
      }
    })
  }],
  help: _i18n.i18n.translate('timelion.help.functions.legendHelpText', {
    defaultMessage: 'Set the position and style of the legend on the plot'
  }),
  fn: function legendFn(args) {
    return (0, _alter2.default)(args, function (eachSeries, position, columns, showTime = true, timeFormat = _lib.DEFAULT_TIME_FORMAT) {
      eachSeries._global = eachSeries._global || {};
      eachSeries._global.legend = eachSeries._global.legend || {};
      eachSeries._global.legend.noColumns = columns;
      eachSeries._global.legend.showTime = showTime;
      eachSeries._global.legend.timeFormat = timeFormat;

      if (position === false) {
        eachSeries._global.legend.show = false;
        eachSeries._global.legend.showTime = false;
      } else {
        eachSeries._global.legend.position = position;
      }

      return eachSeries;
    });
  }
});
module.exports = exports['default'];
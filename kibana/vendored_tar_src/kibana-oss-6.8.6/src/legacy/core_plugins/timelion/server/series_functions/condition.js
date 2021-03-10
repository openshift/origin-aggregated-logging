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

var _arg_type = require('../handlers/lib/arg_type.js');

var _arg_type2 = _interopRequireDefault(_arg_type);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = new _chainable2.default('condition', {
  args: [{
    name: 'inputSeries',
    types: ['seriesList']
  }, {
    name: 'operator', // <, <=, >, >=, ==, !=
    types: ['string'],
    help: _i18n.i18n.translate('timelion.help.functions.condition.args.operatorHelpText', {
      defaultMessage: 'comparison operator to use for comparison, valid operators are eq (equal), ' + 'ne (not equal), lt (less than), lte (less than equal), gt (greater than), gte (greater than equal)'
    }),
    suggestions: [{
      name: 'eq',
      help: _i18n.i18n.translate('timelion.help.functions.condition.args.operator.suggestions.eqHelpText', {
        defaultMessage: 'equal'
      })
    }, {
      name: 'ne',
      help: _i18n.i18n.translate('timelion.help.functions.condition.args.operator.suggestions.neHelpText', {
        defaultMessage: 'not equal'
      })
    }, {
      name: 'lt',
      help: _i18n.i18n.translate('timelion.help.functions.condition.args.operator.suggestions.ltHelpText', {
        defaultMessage: 'less than'
      })
    }, {
      name: 'lte',
      help: _i18n.i18n.translate('timelion.help.functions.condition.args.operator.suggestions.lteHelpText', {
        defaultMessage: 'less than equal'
      })
    }, {
      name: 'gt',
      help: _i18n.i18n.translate('timelion.help.functions.condition.args.operator.suggestions.gtHelpText', {
        defaultMessage: 'greater than'
      })
    }, {
      name: 'gte',
      help: _i18n.i18n.translate('timelion.help.functions.condition.args.operator.suggestions.gteHelpText', {
        defaultMessage: 'greater than equal'
      })
    }]
  }, {
    name: 'if',
    types: ['number', 'seriesList', 'null'],
    help: _i18n.i18n.translate('timelion.help.functions.condition.args.ifHelpText', {
      defaultMessage: 'The value to which the point will be compared. If you pass a seriesList here the first series will be used'
    })
  }, {
    name: 'then',
    types: ['number', 'seriesList', 'null'],
    help: _i18n.i18n.translate('timelion.help.functions.condition.args.thenHelpText', {
      defaultMessage: 'The value the point will be set to if the comparison is true. If you pass a seriesList here the first series will be used'
    })
  }, {
    name: 'else',
    types: ['number', 'seriesList', 'null'],
    help: _i18n.i18n.translate('timelion.help.functions.condition.args.elseHelpText', {
      defaultMessage: 'The value the point will be set to if the comparison is false. If you pass a seriesList here the first series will be used'
    })
  }],
  help: _i18n.i18n.translate('timelion.help.functions.conditionHelpText', {
    defaultMessage: 'Compares each point to a number, or the same point in another series using an operator, ' + 'then sets its value to the result if the condition proves true, with an optional else.'
  }),
  aliases: ['if'],
  fn: function conditionFn(args) {
    const config = args.byName;
    return (0, _alter2.default)(args, function (eachSeries) {
      const data = _lodash2.default.map(eachSeries.data, function (point, i) {
        function getNumber(source) {
          if ((0, _arg_type2.default)(source) === 'number') return source;
          if ((0, _arg_type2.default)(source) === 'null') return null;
          if ((0, _arg_type2.default)(source) === 'seriesList') return source.list[0].data[i][1];
          throw new Error(_i18n.i18n.translate('timelion.serverSideErrors.conditionFunction.wrongArgTypeErrorMessage', {
            defaultMessage: 'must be a number or a seriesList'
          }));
        }

        const ifVal = getNumber(config.if);
        const thenVal = getNumber(config.then);
        const elseVal = _lodash2.default.isUndefined(config.else) ? point[1] : getNumber(config.else);

        const newValue = function () {
          switch (config.operator) {
            case 'lt':
              return point[1] < ifVal ? thenVal : elseVal;
            case 'lte':
              return point[1] <= ifVal ? thenVal : elseVal;
            case 'gt':
              return point[1] > ifVal ? thenVal : elseVal;
            case 'gte':
              return point[1] >= ifVal ? thenVal : elseVal;
            case 'eq':
              return point[1] === ifVal ? thenVal : elseVal;
            case 'ne':
              return point[1] !== ifVal ? thenVal : elseVal;
            default:
              throw new Error(_i18n.i18n.translate('timelion.serverSideErrors.conditionFunction.unknownOperatorErrorMessage', {
                defaultMessage: 'Unknown operator'
              }));
          }
        }();

        return [point[0], newValue];
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
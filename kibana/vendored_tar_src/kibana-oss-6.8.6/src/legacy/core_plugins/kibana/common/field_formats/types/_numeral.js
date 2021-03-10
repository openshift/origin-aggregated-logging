'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createNumeralFormat = createNumeralFormat;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _numeral = require('@elastic/numeral');

var _numeral2 = _interopRequireDefault(_numeral);

var _languages = require('@elastic/numeral/languages');

var _languages2 = _interopRequireDefault(_languages);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const numeralInst = (0, _numeral2.default)(); /*
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

_languages2.default.forEach(function (numeralLanguage) {
  _numeral2.default.language(numeralLanguage.id, numeralLanguage.lang);
});

function createNumeralFormat(FieldFormat, opts) {
  class NumeralFormat extends FieldFormat {

    constructor(params, getConfig) {
      super(params);
      this.getConfig = getConfig;
    }

    getParamDefaults() {
      if (_lodash2.default.has(opts, 'getParamDefaults')) {
        return opts.getParamDefaults(this.getConfig);
      }

      return {
        pattern: this.getConfig(`format:${opts.id}:defaultPattern`)
      };
    }

    _convert(val) {
      if (val === -Infinity) return '-∞';
      if (val === +Infinity) return '+∞';
      if (typeof val !== 'number') {
        val = parseFloat(val);
      }

      if (isNaN(val)) return '';

      const previousLocale = _numeral2.default.language();
      const defaultLocale = this.getConfig && this.getConfig('format:number:defaultLocale') || 'en';
      _numeral2.default.language(defaultLocale);

      const formatted = numeralInst.set(val).format(this.param('pattern'));

      _numeral2.default.language(previousLocale);

      return opts.afterConvert ? opts.afterConvert.call(this, formatted) : formatted;
    }
  }

  NumeralFormat.id = opts.id;
  NumeralFormat.title = opts.title;
  NumeralFormat.fieldType = 'number';
  if (opts.prototype) {
    _lodash2.default.assign(NumeralFormat.prototype, opts.prototype);
  }

  return NumeralFormat;
}
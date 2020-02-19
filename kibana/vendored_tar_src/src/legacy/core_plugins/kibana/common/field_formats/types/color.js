'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createColorFormat = createColorFormat;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _as_pretty_string = require('../../utils/as_pretty_string');

var _color_default = require('./color_default');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const convertTemplate = _lodash2.default.template('<span style="<%- style %>"><%- val %></span>'); /*
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

function createColorFormat(FieldFormat) {
  class ColorFormat extends FieldFormat {
    getParamDefaults() {
      return {
        fieldType: null, // populated by editor, see controller below
        colors: [_lodash2.default.cloneDeep(_color_default.DEFAULT_COLOR)]
      };
    }

    findColorRuleForVal(val) {
      switch (this.param('fieldType')) {
        case 'string':
          return _lodash2.default.findLast(this.param('colors'), colorParam => {
            return new RegExp(colorParam.regex).test(val);
          });

        case 'number':
          return _lodash2.default.findLast(this.param('colors'), ({ range }) => {
            if (!range) return;
            const [start, end] = range.split(':');
            return val >= Number(start) && val <= Number(end);
          });

        default:
          return null;
      }
    }

  }

  ColorFormat.id = 'color';
  ColorFormat.title = 'Color';
  ColorFormat.fieldType = ['number', 'string'];
  ColorFormat.prototype._convert = {
    html(val) {
      const color = this.findColorRuleForVal(val);
      if (!color) return _lodash2.default.escape((0, _as_pretty_string.asPrettyString)(val));

      let style = '';
      if (color.text) style += `color: ${color.text};`;
      if (color.background) style += `background-color: ${color.background};`;
      return convertTemplate({ val, style });
    }
  };

  return ColorFormat;
}
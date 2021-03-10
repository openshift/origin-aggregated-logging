'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createTruncateFormat = createTruncateFormat;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const omission = '...'; /*
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

function createTruncateFormat(FieldFormat) {
  var _class, _temp;

  return _temp = _class = class TruncateFormat extends FieldFormat {
    _convert(val) {
      const length = this.param('fieldLength');
      if (length > 0) {
        return _lodash2.default.trunc(val, {
          'length': length + omission.length,
          'omission': omission
        });
      }

      return val;
    }

  }, _class.id = 'truncate', _class.title = 'Truncated String', _class.fieldType = ['string'], _temp;
}
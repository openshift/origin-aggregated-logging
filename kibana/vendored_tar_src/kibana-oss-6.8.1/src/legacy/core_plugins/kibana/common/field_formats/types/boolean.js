'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createBoolFormat = createBoolFormat;

var _as_pretty_string = require('../../utils/as_pretty_string');

function createBoolFormat(FieldFormat) {
  var _class, _temp;

  return _temp = _class = class BoolFormat extends FieldFormat {
    _convert(value) {
      if (typeof value === 'string') {
        value = value.trim().toLowerCase();
      }

      switch (value) {
        case false:
        case 0:
        case 'false':
        case 'no':
          return 'false';
        case true:
        case 1:
        case 'true':
        case 'yes':
          return 'true';
        default:
          return (0, _as_pretty_string.asPrettyString)(value);
      }
    }

  }, _class.id = 'boolean', _class.title = 'Boolean', _class.fieldType = ['boolean', 'number', 'string'], _temp;
} /*
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
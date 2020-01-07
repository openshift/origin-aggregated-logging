'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = parseSheet;

var _i18n = require('@kbn/i18n');

var _fs = require('fs');

var _fs2 = _interopRequireDefault(_fs);

var _path = require('path');

var _path2 = _interopRequireDefault(_path);

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _pegjs = require('pegjs');

var _pegjs2 = _interopRequireDefault(_pegjs);

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

const grammar = _fs2.default.readFileSync(_path2.default.resolve(__dirname, '../../../public/chain.peg'), 'utf8');

const Parser = _pegjs2.default.buildParser(grammar);

function parseSheet(sheet) {
  return _lodash2.default.map(sheet, function (plot) {
    try {
      return Parser.parse(plot).tree;
    } catch (e) {
      if (e.expected) {
        throw new Error(_i18n.i18n.translate('timelion.serverSideErrors.sheetParseErrorMessage', {
          defaultMessage: 'Expected: {expectedDescription} @ character {column}',
          values: {
            expectedDescription: e.expected[0].description,
            column: e.column
          }
        }));
      } else {
        throw e;
      }
    }
  });
}
module.exports = exports['default'];
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.registerFieldFormats = registerFieldFormats;

var _url = require('../../common/field_formats/types/url');

var _bytes = require('../../common/field_formats/types/bytes');

var _date = require('../../common/field_formats/types/date');

var _duration = require('../../common/field_formats/types/duration');

var _ip = require('../../common/field_formats/types/ip');

var _number = require('../../common/field_formats/types/number');

var _percent = require('../../common/field_formats/types/percent');

var _string = require('../../common/field_formats/types/string');

var _source = require('../../common/field_formats/types/source');

var _color = require('../../common/field_formats/types/color');

var _truncate = require('../../common/field_formats/types/truncate');

var _boolean = require('../../common/field_formats/types/boolean');

var _static_lookup = require('../../common/field_formats/types/static_lookup');

function registerFieldFormats(server) {
  server.registerFieldFormat(_url.createUrlFormat);
  server.registerFieldFormat(_bytes.createBytesFormat);
  server.registerFieldFormat(_date.createDateFormat);
  server.registerFieldFormat(_duration.createDurationFormat);
  server.registerFieldFormat(_ip.createIpFormat);
  server.registerFieldFormat(_number.createNumberFormat);
  server.registerFieldFormat(_percent.createPercentFormat);
  server.registerFieldFormat(_string.createStringFormat);
  server.registerFieldFormat(_source.createSourceFormat);
  server.registerFieldFormat(_color.createColorFormat);
  server.registerFieldFormat(_truncate.createTruncateFormat);
  server.registerFieldFormat(_boolean.createBoolFormat);
  server.registerFieldFormat(_static_lookup.createStaticLookupFormat);
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
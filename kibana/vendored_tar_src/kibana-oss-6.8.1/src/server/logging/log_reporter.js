'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getLoggerStream = getLoggerStream;

var _goodSqueeze = require('good-squeeze');

var _fs = require('fs');

var _log_format_json = require('./log_format_json');

var _log_format_json2 = _interopRequireDefault(_log_format_json);

var _log_format_string = require('./log_format_string');

var _log_format_string2 = _interopRequireDefault(_log_format_string);

var _log_interceptor = require('./log_interceptor');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function getLoggerStream({ events, config }) {
  const squeeze = new _goodSqueeze.Squeeze(events);
  const format = config.json ? new _log_format_json2.default(config) : new _log_format_string2.default(config);
  const logInterceptor = new _log_interceptor.LogInterceptor();

  let dest;
  if (config.dest === 'stdout') {
    dest = process.stdout;
  } else {
    dest = (0, _fs.createWriteStream)(config.dest, {
      flags: 'a',
      encoding: 'utf8'
    });

    logInterceptor.on('end', () => {
      dest.end();
    });
  }

  logInterceptor.pipe(squeeze).pipe(format).pipe(dest);

  return logInterceptor;
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
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _stream = require('stream');

var _stream2 = _interopRequireDefault(_stream);

var _momentTimezone = require('moment-timezone');

var _momentTimezone2 = _interopRequireDefault(_momentTimezone);

var _lodash = require('lodash');

var _numeral = require('@elastic/numeral');

var _numeral2 = _interopRequireDefault(_numeral);

var _chalk = require('chalk');

var _chalk2 = _interopRequireDefault(_chalk);

var _jsonStringifySafe = require('json-stringify-safe');

var _jsonStringifySafe2 = _interopRequireDefault(_jsonStringifySafe);

var _querystring = require('querystring');

var _querystring2 = _interopRequireDefault(_querystring);

var _apply_filters_to_keys = require('./apply_filters_to_keys');

var _apply_filters_to_keys2 = _interopRequireDefault(_apply_filters_to_keys);

var _util = require('util');

var _log_with_metadata = require('./log_with_metadata');

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

function serializeError(err = {}) {
  return {
    message: err.message,
    name: err.name,
    stack: err.stack,
    code: err.code,
    signal: err.signal
  };
}

const levelColor = function (code) {
  if (code < 299) return _chalk2.default.green(code);
  if (code < 399) return _chalk2.default.yellow(code);
  if (code < 499) return _chalk2.default.magentaBright(code);
  return _chalk2.default.red(code);
};

class TransformObjStream extends _stream2.default.Transform {
  constructor(config) {
    super({
      readableObjectMode: false,
      writableObjectMode: true
    });
    this.config = config;
  }

  filter(data) {
    if (!this.config.filter) return data;
    return (0, _apply_filters_to_keys2.default)(data, this.config.filter);
  }

  _transform(event, enc, next) {
    const data = this.filter(this.readEvent(event));
    this.push(this.format(data) + '\n');
    next();
  }

  extractAndFormatTimestamp(data, format) {
    const { timezone } = this.config;
    const date = (0, _momentTimezone2.default)(data['@timestamp']);
    if (timezone) {
      date.tz(timezone);
    }
    return date.format(format);
  }

  readEvent(event) {
    const data = {
      type: event.event,
      '@timestamp': event.timestamp,
      tags: [].concat(event.tags || []),
      pid: event.pid
    };

    if (data.type === 'response') {
      _lodash._.defaults(data, _lodash._.pick(event, ['method', 'statusCode']));

      const source = (0, _lodash.get)(event, 'source', {});
      data.req = {
        url: event.path,
        method: event.method || '',
        headers: event.headers,
        remoteAddress: source.remoteAddress,
        userAgent: source.remoteAddress,
        referer: source.referer
      };

      let contentLength = 0;
      if (typeof event.responsePayload === 'object') {
        contentLength = (0, _jsonStringifySafe2.default)(event.responsePayload).length;
      } else {
        contentLength = String(event.responsePayload).length;
      }

      data.res = {
        statusCode: event.statusCode,
        responseTime: event.responseTime,
        contentLength: contentLength
      };

      const query = _querystring2.default.stringify(event.query);
      if (query) data.req.url += '?' + query;

      data.message = data.req.method.toUpperCase() + ' ';
      data.message += data.req.url;
      data.message += ' ';
      data.message += levelColor(data.res.statusCode);
      data.message += ' ';
      data.message += _chalk2.default.gray(data.res.responseTime + 'ms');
      data.message += _chalk2.default.gray(' - ' + (0, _numeral2.default)(contentLength).format('0.0b'));
    } else if (data.type === 'ops') {
      _lodash._.defaults(data, _lodash._.pick(event, ['pid', 'os', 'proc', 'load']));
      data.message = _chalk2.default.gray('memory: ');
      data.message += (0, _numeral2.default)((0, _lodash.get)(data, 'proc.mem.heapUsed')).format('0.0b');
      data.message += ' ';
      data.message += _chalk2.default.gray('uptime: ');
      data.message += (0, _numeral2.default)((0, _lodash.get)(data, 'proc.uptime')).format('00:00:00');
      data.message += ' ';
      data.message += _chalk2.default.gray('load: [');
      data.message += (0, _lodash.get)(data, 'os.load', []).map(function (val) {
        return (0, _numeral2.default)(val).format('0.00');
      }).join(' ');
      data.message += _chalk2.default.gray(']');
      data.message += ' ';
      data.message += _chalk2.default.gray('delay: ');
      data.message += (0, _numeral2.default)((0, _lodash.get)(data, 'proc.delay')).format('0.000');
    } else if (data.type === 'error') {
      data.level = 'error';
      data.error = serializeError(event.error);
      data.url = event.url;
      const message = (0, _lodash.get)(event, 'error.message');
      data.message = message || 'Unknown error (no message)';
    } else if (event.error instanceof Error) {
      data.type = 'error';
      data.level = _lodash._.contains(event.tags, 'fatal') ? 'fatal' : 'error';
      data.error = serializeError(event.error);
      const message = (0, _lodash.get)(event, 'error.message');
      data.message = message || 'Unknown error object (no message)';
    } else if (_log_with_metadata.logWithMetadata.isLogEvent(event.data)) {
      _lodash._.assign(data, _log_with_metadata.logWithMetadata.getLogEventData(event.data));
    } else {
      data.message = _lodash._.isString(event.data) ? event.data : (0, _util.inspect)(event.data);
    }
    return data;
  }
}
exports.default = TransformObjStream;
module.exports = exports['default'];
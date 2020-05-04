'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; /*
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

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _boom = require('boom');

var _boom2 = _interopRequireDefault(_boom);

var _bluebird = require('bluebird');

var _bluebird2 = _interopRequireDefault(_bluebird);

var _fs = require('fs');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const writeFile = _bluebird2.default.promisify(require('fs').writeFile);

exports.default = _bluebird2.default.method(function (kbnServer, server, config) {
  const path = config.get('pid.file');
  if (!path) return;

  const pid = String(process.pid);

  return writeFile(path, pid, { flag: 'wx' }).catch(function (err) {
    if (err.code !== 'EEXIST') throw err;

    const message = `pid file already exists at ${path}`;
    const metadata = {
      path: path,
      pid: pid
    };

    if (config.get('pid.exclusive')) {
      throw _boom2.default.internal(message, _extends({ message }, metadata));
    } else {
      server.log(['pid', 'warning'], message, metadata);
    }

    return writeFile(path, pid);
  }).then(function () {

    server.logWithMetadata(['pid', 'debug'], `wrote pid file to ${path}`, {
      path: path,
      pid: pid
    });

    const clean = _lodash2.default.once(function () {
      (0, _fs.unlinkSync)(path);
    });

    process.once('exit', clean); // for "natural" exits
    process.once('SIGINT', function () {
      // for Ctrl-C exits
      clean();

      // resend SIGINT
      process.kill(process.pid, 'SIGINT');
    });

    process.on('unhandledRejection', function (reason) {
      server.log(['warning'], `Detected an unhandled Promise rejection.\n${reason}`);
    });
  });
});
module.exports = exports['default'];
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

exports.parseConfig = parseConfig;

var _util = require('util');

var _util2 = _interopRequireDefault(_util);

var _url = require('url');

var _url2 = _interopRequireDefault(_url);

var _lodash = require('lodash');

var _fs = require('fs');

var _bluebird = require('bluebird');

var _bluebird2 = _interopRequireDefault(_bluebird);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const readFile = file => (0, _fs.readFileSync)(file, 'utf8');

function parseConfig(serverConfig = {}, { ignoreCertAndKey = false } = {}) {
  const config = _extends({
    keepAlive: true
  }, (0, _lodash.pick)(serverConfig, ['plugins', 'apiVersion', 'keepAlive', 'pingTimeout', 'requestTimeout', 'log', 'logQueries', 'sniffOnStart', 'sniffInterval', 'sniffOnConnectionFault', 'hosts']));

  const mapHost = nodeUrl => {
    const uri = _url2.default.parse(nodeUrl);
    return {
      host: uri.hostname,
      port: uri.port,
      protocol: uri.protocol,
      path: uri.pathname,
      query: uri.query,
      headers: serverConfig.customHeaders
    };
  };

  if (serverConfig.hosts) {
    config.hosts = serverConfig.hosts.map(mapHost);
  }

  // Auth
  if (serverConfig.auth !== false && serverConfig.username && serverConfig.password) {
    config.hosts.forEach(host => {
      host.auth = _util2.default.format('%s:%s', serverConfig.username, serverConfig.password);
    });
  }

  // SSL
  config.ssl = {};

  const verificationMode = (0, _lodash.get)(serverConfig, 'ssl.verificationMode');
  switch (verificationMode) {
    case 'none':
      config.ssl.rejectUnauthorized = false;
      break;
    case 'certificate':
      config.ssl.rejectUnauthorized = true;

      // by default, NodeJS is checking the server identify
      config.ssl.checkServerIdentity = _lodash.noop;
      break;
    case 'full':
      config.ssl.rejectUnauthorized = true;
      break;
    default:
      throw new Error(`Unknown ssl verificationMode: ${verificationMode}`);
  }

  if ((0, _lodash.size)((0, _lodash.get)(serverConfig, 'ssl.certificateAuthorities'))) {
    config.ssl.ca = serverConfig.ssl.certificateAuthorities.map(readFile);
  }

  // Add client certificate and key if required by elasticsearch
  if (!ignoreCertAndKey && (0, _lodash.get)(serverConfig, 'ssl.certificate') && (0, _lodash.get)(serverConfig, 'ssl.key')) {
    config.ssl.cert = readFile(serverConfig.ssl.certificate);
    config.ssl.key = readFile(serverConfig.ssl.key);
    config.ssl.passphrase = serverConfig.ssl.keyPassphrase;
  }

  config.defer = () => _bluebird2.default.defer();

  return config;
}
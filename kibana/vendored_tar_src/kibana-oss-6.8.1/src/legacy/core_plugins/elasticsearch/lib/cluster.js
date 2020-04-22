'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Cluster = undefined;

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

var _elasticsearch = require('elasticsearch');

var _elasticsearch2 = _interopRequireDefault(_elasticsearch);

var _lodash = require('lodash');

var _toPath = require('lodash/internal/toPath');

var _toPath2 = _interopRequireDefault(_toPath);

var _boom = require('boom');

var _boom2 = _interopRequireDefault(_boom);

var _filter_headers = require('./filter_headers');

var _filter_headers2 = _interopRequireDefault(_filter_headers);

var _parse_config = require('./parse_config');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

class Cluster {
  constructor(config) {
    _initialiseProps.call(this);

    this._config = _extends({}, config);
    this.errors = _elasticsearch2.default.errors;

    this._clients = new Set();
    this._client = this.createClient();
    this._noAuthClient = this.createClient({ auth: false }, { ignoreCertAndKey: !this.getSsl().alwaysPresentCertificate });

    return this;
  }

  close() {
    for (const client of this._clients) {
      client.close();
    }

    this._clients.clear();
  }

}

exports.Cluster = Cluster;

var _initialiseProps = function () {
  this.callWithRequest = (req = {}, endpoint, clientParams = {}, options = {}) => {
    if (req.headers) {
      const filteredHeaders = (0, _filter_headers2.default)(req.headers, this.getRequestHeadersWhitelist());
      (0, _lodash.set)(clientParams, 'headers', filteredHeaders);
    }

    return callAPI(this._noAuthClient, endpoint, clientParams, options);
  };

  this.callWithInternalUser = (endpoint, clientParams = {}, options = {}) => {
    return callAPI(this._client, endpoint, clientParams, options);
  };

  this.getRequestHeadersWhitelist = () => getClonedProperty(this._config, 'requestHeadersWhitelist');

  this.getCustomHeaders = () => getClonedProperty(this._config, 'customHeaders');

  this.getRequestTimeout = () => getClonedProperty(this._config, 'requestTimeout');

  this.getHosts = () => getClonedProperty(this._config, 'hosts');

  this.getSsl = () => getClonedProperty(this._config, 'ssl');

  this.getClient = () => this._client;

  this.createClient = (configOverrides, parseOptions) => {
    const config = _extends({}, this._getClientConfig(), configOverrides);

    const client = new _elasticsearch2.default.Client((0, _parse_config.parseConfig)(config, parseOptions));
    this._clients.add(client);
    return client;
  };

  this._getClientConfig = () => {
    return getClonedProperties(this._config, ['hosts', 'ssl', 'username', 'password', 'customHeaders', 'plugins', 'apiVersion', 'keepAlive', 'pingTimeout', 'requestTimeout', 'sniffOnStart', 'sniffInterval', 'sniffOnConnectionFault', 'log']);
  };
};

function callAPI(client, endpoint, clientParams = {}, options = {}) {
  const wrap401Errors = options.wrap401Errors !== false;
  const clientPath = (0, _toPath2.default)(endpoint);
  const api = (0, _lodash.get)(client, clientPath);

  let apiContext = (0, _lodash.get)(client, clientPath.slice(0, -1));
  if ((0, _lodash.isEmpty)(apiContext)) {
    apiContext = client;
  }

  if (!api) {
    throw new Error(`called with an invalid endpoint: ${endpoint}`);
  }

  return api.call(apiContext, clientParams).catch(err => {
    if (!wrap401Errors || err.statusCode !== 401) {
      return Promise.reject(err);
    }

    const boomError = _boom2.default.boomify(err, { statusCode: err.statusCode });
    const wwwAuthHeader = (0, _lodash.get)(err, 'body.error.header[WWW-Authenticate]');
    boomError.output.headers['WWW-Authenticate'] = wwwAuthHeader || 'Basic realm="Authorization Required"';

    throw boomError;
  });
}

function getClonedProperties(config, paths) {
  return (0, _lodash.cloneDeep)(paths ? (0, _lodash.pick)(config, paths) : config);
}

function getClonedProperty(config, path) {
  return (0, _lodash.cloneDeep)(path ? (0, _lodash.get)(config, path) : config);
}
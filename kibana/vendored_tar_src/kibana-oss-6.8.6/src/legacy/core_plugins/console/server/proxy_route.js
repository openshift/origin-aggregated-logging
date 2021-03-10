'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createProxyRoute = undefined;

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

var _joi = require('joi');

var _joi2 = _interopRequireDefault(_joi);

var _boom = require('boom');

var _boom2 = _interopRequireDefault(_boom);

var _wreck = require('wreck');

var _wreck2 = _interopRequireDefault(_wreck);

var _lodash = require('lodash');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function resolveUri(base, path) {
  let pathToUse = `${(0, _lodash.trimRight)(base, '/')}/${(0, _lodash.trimLeft)(path, '/')}`;
  const questionMarkIndex = pathToUse.indexOf('?');
  // no query string in pathToUse, append '?pretty'
  if (questionMarkIndex === -1) {
    pathToUse = `${pathToUse}?pretty`;
  } else {
    // pathToUse has query string, append '&pretty'
    pathToUse = `${pathToUse}&pretty`;
  }
  return pathToUse;
}

function extendCommaList(obj, property, value) {
  obj[property] = (obj[property] ? obj[property] + ',' : '') + value;
}

function getProxyHeaders(req) {
  const headers = {};

  if (req.info.remotePort && req.info.remoteAddress) {
    // see https://git.io/vytQ7
    extendCommaList(headers, 'x-forwarded-for', req.info.remoteAddress);
    extendCommaList(headers, 'x-forwarded-port', req.info.remotePort);
    extendCommaList(headers, 'x-forwarded-proto', req.server.info.protocol);
    extendCommaList(headers, 'x-forwarded-host', req.info.host);
  }

  const contentType = req.headers['content-type'];
  if (contentType) {
    headers['content-type'] = contentType;
  }

  return headers;
}

const createProxyRoute = exports.createProxyRoute = ({
  baseUrl = '/',
  pathFilters = [/.*/],
  getConfigForReq = () => ({})
}) => ({
  path: '/api/console/proxy',
  method: 'POST',
  config: {
    payload: {
      output: 'stream',
      parse: false
    },

    validate: {
      query: _joi2.default.object().keys({
        method: _joi2.default.string().valid('HEAD', 'GET', 'POST', 'PUT', 'DELETE').insensitive().required(),
        path: _joi2.default.string().required()
      }).unknown(true)
    },

    pre: [function filterPath(req) {
      const { path } = req.query;

      if (pathFilters.some(re => re.test(path))) {
        return null;
      }

      const err = _boom2.default.forbidden();
      err.output.payload = `Error connecting to '${path}':\n\nUnable to send requests to that path.`;
      err.output.headers['content-type'] = 'text/plain';
      throw err;
    }],

    handler: async (req, h) => {
      const { payload, query } = req;
      const { path, method } = query;
      const uri = resolveUri(baseUrl, path);

      const {
        timeout,
        rejectUnauthorized,
        agent,
        headers
      } = getConfigForReq(req, uri);

      const wreckOptions = {
        payload,
        timeout,
        rejectUnauthorized,
        agent,
        headers: _extends({}, headers, getProxyHeaders(req))
      };

      const esResponse = await _wreck2.default.request(method, uri, wreckOptions);

      if (method.toUpperCase() !== 'HEAD') {
        return h.response(esResponse).code(esResponse.statusCode).header('warning', esResponse.headers.warning);
      }

      return h.response(`${esResponse.statusCode} - ${esResponse.statusMessage}`).code(esResponse.statusCode).type('text/plain').header('warning', esResponse.headers.warning);
    }
  }
});
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = mapUri;

var _lodash = require('lodash');

var _url = require('url');

var _filter_headers = require('./filter_headers');

var _filter_headers2 = _interopRequireDefault(_filter_headers);

var _set_headers = require('./set_headers');

var _set_headers2 = _interopRequireDefault(_set_headers);

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

function mapUri(cluster, proxyPrefix) {
  function joinPaths(pathA, pathB) {
    return (0, _lodash.trimRight)(pathA, '/') + '/' + (0, _lodash.trimLeft)(pathB, '/');
  }

  return function (request) {
    const {
      protocol: esUrlProtocol,
      slashes: esUrlHasSlashes,
      auth: esUrlAuth,
      hostname: esUrlHostname,
      port: esUrlPort,
      pathname: esUrlBasePath,
      query: esUrlQuery
    } = (0, _url.parse)(cluster.getUrl(), true);

    // copy most url components directly from elasticsearch.hosts
    const mappedUrlComponents = {
      protocol: esUrlProtocol,
      slashes: esUrlHasSlashes,
      auth: esUrlAuth,
      hostname: esUrlHostname,
      port: esUrlPort
    };

    // pathname
    const reqSubPath = request.path.replace(proxyPrefix, '');
    mappedUrlComponents.pathname = joinPaths(esUrlBasePath, reqSubPath);

    // querystring
    const mappedQuery = (0, _lodash.defaults)((0, _lodash.omit)(request.query, '_'), esUrlQuery);
    if (Object.keys(mappedQuery).length) {
      mappedUrlComponents.query = mappedQuery;
    }

    const filteredHeaders = (0, _filter_headers2.default)(request.headers, cluster.getRequestHeadersWhitelist());
    const mappedHeaders = (0, _set_headers2.default)(filteredHeaders, cluster.getCustomHeaders());
    const mappedUrl = (0, _url.format)(mappedUrlComponents);
    return { uri: mappedUrl, headers: mappedHeaders };
  };
}
module.exports = exports['default'];
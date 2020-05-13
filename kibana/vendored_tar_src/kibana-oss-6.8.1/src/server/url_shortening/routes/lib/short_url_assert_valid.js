'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.shortUrlAssertValid = shortUrlAssertValid;

var _url = require('url');

var _lodash = require('lodash');

var _boom = require('boom');

var _boom2 = _interopRequireDefault(_boom);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function shortUrlAssertValid(url) {
  const { protocol, hostname, pathname } = (0, _url.parse)(url);

  if (protocol) {
    throw _boom2.default.notAcceptable(`Short url targets cannot have a protocol, found "${protocol}"`);
  }

  if (hostname) {
    throw _boom2.default.notAcceptable(`Short url targets cannot have a hostname, found "${hostname}"`);
  }

  const pathnameParts = (0, _lodash.trim)(pathname, '/').split('/');
  if (pathnameParts.length !== 2) {
    throw _boom2.default.notAcceptable(`Short url target path must be in the format "/app/{{appId}}", found "${pathname}"`);
  }
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
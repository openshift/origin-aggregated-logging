'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createRoutes = createRoutes;

var _short_url_error = require('./lib/short_url_error');

var _short_url_assert_valid = require('./lib/short_url_assert_valid');

var _short_url_lookup = require('./lib/short_url_lookup');

var _goto = require('./goto');

var _shorten_url = require('./shorten_url');

function createRoutes(server) {
  const shortUrlLookup = (0, _short_url_lookup.shortUrlLookupProvider)(server);

  server.route((0, _goto.createGotoRoute)({ server, shortUrlLookup }));
  server.route((0, _shorten_url.createShortenUrlRoute)({ shortUrlLookup }));

  // TODO remove deprecated '/shorten' API in master (7.0)
  server.route({
    method: 'POST',
    path: '/shorten',
    handler: async function (request) {
      server.log(['warning', 'deprecation'], `'/shorten' API has been deprecated and will be removed in 7.0, use the '/api/shorten_url' API instead`);
      try {
        (0, _short_url_assert_valid.shortUrlAssertValid)(request.payload.url);
        const urlId = await shortUrlLookup.generateUrlId(request.payload.url, request);
        return urlId;
      } catch (err) {
        return (0, _short_url_error.handleShortUrlError)(err);
      }
    }
  });
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
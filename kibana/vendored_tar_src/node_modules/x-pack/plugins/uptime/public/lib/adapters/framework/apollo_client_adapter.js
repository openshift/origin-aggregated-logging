"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const apollo_cache_inmemory_1 = require("apollo-cache-inmemory");
const apollo_client_1 = require("apollo-client");
const apollo_link_http_1 = require("apollo-link-http");
exports.createApolloClient = (uri, xsrfHeader) => new apollo_client_1.ApolloClient({
    link: new apollo_link_http_1.HttpLink({ uri, credentials: 'same-origin', headers: { 'kbn-xsrf': xsrfHeader } }),
    cache: new apollo_cache_inmemory_1.InMemoryCache({ dataIdFromObject: () => undefined }),
});

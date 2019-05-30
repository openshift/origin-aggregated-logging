"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const apollo_server_core_1 = require("apollo-server-core");
const graphql_1 = require("../../../graphql");
exports.uptimeGraphQLHapiPlugin = {
    name: 'uptimeGraphQL',
    register: (server, options) => {
        server.route({
            options: options.route,
            handler: async (request, h) => {
                try {
                    const { method } = request;
                    const query = method === 'post'
                        ? request.payload
                        : request.query;
                    const graphQLResponse = await apollo_server_core_1.runHttpQuery([request], {
                        method: method.toUpperCase(),
                        options: options.graphQLOptions,
                        query,
                    });
                    return h.response(graphQLResponse).type('application/json');
                }
                catch (error) {
                    if (error.isGraphQLError === true) {
                        return h
                            .response(error.message)
                            .code(error.statusCode)
                            .type('application/json');
                    }
                    return h.response(error).type('application/json');
                }
            },
            method: ['get', 'post'],
            path: options.path || graphql_1.DEFAULT_GRAPHQL_PATH,
            vhost: options.vhost || undefined,
        });
    },
};

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const GraphiQL = tslib_1.__importStar(require("apollo-server-module-graphiql"));
const boom_1 = tslib_1.__importDefault(require("boom"));
const apollo_server_core_1 = require("apollo-server-core");
exports.graphqlHapi = {
    name: 'graphql',
    register: (server, options) => {
        if (!options || !options.graphqlOptions) {
            throw new Error('Apollo Server requires options.');
        }
        server.route({
            options: options.route || {},
            handler: async (request, h) => {
                try {
                    const query = request.method === 'post'
                        ? request.payload
                        : request.query;
                    const gqlResponse = await apollo_server_core_1.runHttpQuery([request], {
                        method: request.method.toUpperCase(),
                        options: options.graphqlOptions,
                        query,
                    });
                    return h.response(gqlResponse).type('application/json');
                }
                catch (error) {
                    if ('HttpQueryError' !== error.name) {
                        const queryError = boom_1.default.boomify(error);
                        queryError.output.payload.message = error.message;
                        return queryError;
                    }
                    if (error.isGraphQLError === true) {
                        return h
                            .response(error.message)
                            .code(error.statusCode)
                            .type('application/json');
                    }
                    const genericError = new boom_1.default(error.message, { statusCode: error.statusCode });
                    if (error.headers) {
                        Object.keys(error.headers).forEach(header => {
                            genericError.output.headers[header] = error.headers[header];
                        });
                    }
                    // Boom hides the error when status code is 500
                    genericError.output.payload.message = error.message;
                    throw genericError;
                }
            },
            method: ['GET', 'POST'],
            path: options.path || '/graphql',
            vhost: options.vhost || undefined,
        });
    },
};
exports.graphiqlHapi = {
    name: 'graphiql',
    register: (server, options) => {
        if (!options || !options.graphiqlOptions) {
            throw new Error('Apollo Server GraphiQL requires options.');
        }
        server.route({
            options: options.route || {},
            handler: async (request, h) => {
                const graphiqlString = await GraphiQL.resolveGraphiQLString(request.query, options.graphiqlOptions, request);
                return h.response(graphiqlString).type('text/html');
            },
            method: 'GET',
            path: options.path || '/graphiql',
        });
    },
};

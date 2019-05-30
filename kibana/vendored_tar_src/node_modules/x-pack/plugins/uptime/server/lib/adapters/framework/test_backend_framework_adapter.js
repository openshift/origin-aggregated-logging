"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class UMTestBackendFrameworkAdapter {
    constructor(server) {
        this.server = server;
    }
    registerRoute(route) {
        const { config, method, path, handler } = route;
        this.server.route({
            config,
            handler,
            method,
            path,
        });
    }
    registerGraphQLEndpoint(routePath, schema) {
        this.server.register({
            options: {
                schema,
            },
            path: routePath,
        });
    }
}
exports.UMTestBackendFrameworkAdapter = UMTestBackendFrameworkAdapter;

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const boom_1 = tslib_1.__importDefault(require("boom"));
exports.createRouteWithAuth = (libs, routeCreator) => {
    const restRoute = routeCreator(libs);
    const { handler, method, path, options } = restRoute;
    const authHandler = async (request, h) => {
        if (libs.auth.requestIsValid(request)) {
            return await handler(request, h);
        }
        return boom_1.default.badRequest();
    };
    return {
        method,
        path,
        options,
        handler: authHandler,
    };
};

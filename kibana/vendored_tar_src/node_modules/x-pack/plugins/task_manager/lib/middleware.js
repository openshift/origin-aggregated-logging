"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
function addMiddlewareToChain(prevMiddleware, middleware) {
    const beforeSave = middleware.beforeSave
        ? (params) => middleware.beforeSave(params).then(prevMiddleware.beforeSave)
        : prevMiddleware.beforeSave;
    const beforeRun = middleware.beforeRun
        ? (params) => middleware.beforeRun(params).then(prevMiddleware.beforeRun)
        : prevMiddleware.beforeRun;
    return {
        beforeSave,
        beforeRun,
    };
}
exports.addMiddlewareToChain = addMiddlewareToChain;

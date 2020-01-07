"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adapter_types_1 = require("../lib/adapters/framework/adapter_types");
function wrapRequest(req) {
    const { params, payload, query, headers, info } = req;
    const isAuthenticated = headers.authorization != null;
    return {
        // @ts-ignore -- partial applucation, adapter adds other user data
        user: isAuthenticated
            ? {
                kind: 'authenticated',
                [adapter_types_1.internalAuthData]: headers,
            }
            : {
                kind: 'unauthenticated',
            },
        headers,
        info,
        params,
        payload,
        query,
    };
}
exports.wrapRequest = wrapRequest;

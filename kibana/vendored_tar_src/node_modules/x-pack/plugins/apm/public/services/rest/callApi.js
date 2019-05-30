"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const lodash_1 = require("lodash");
const kfetch_1 = require("ui/kfetch");
function fetchOptionsWithDebug(fetchOptions) {
    const debugEnabled = sessionStorage.getItem('apm_debug') === 'true' &&
        lodash_1.startsWith(fetchOptions.pathname, '/api/apm');
    if (!debugEnabled) {
        return fetchOptions;
    }
    return {
        ...fetchOptions,
        query: {
            ...fetchOptions.query,
            _debug: true
        }
    };
}
async function callApi(fetchOptions, options) {
    const combinedFetchOptions = fetchOptionsWithDebug(fetchOptions);
    return await kfetch_1.kfetch(combinedFetchOptions, options);
}
exports.callApi = callApi;

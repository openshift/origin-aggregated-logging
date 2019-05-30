"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
// @ts-ignore
const boom_1 = require("boom");
function wrapError(error) {
    if (error.isBoom) {
        return error;
    }
    return boom_1.boomify(error, { statusCode: error.status });
}
exports.wrapError = wrapError;

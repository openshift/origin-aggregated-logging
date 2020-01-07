"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const boom_1 = tslib_1.__importDefault(require("boom"));
function wrapError(error) {
    return boom_1.default.boomify(error, { statusCode: getErrorStatusCode(error) });
}
exports.wrapError = wrapError;
/**
 * Extracts error code from Boom and Elasticsearch "native" errors.
 * @param error Error instance to extract status code from.
 */
function getErrorStatusCode(error) {
    return boom_1.default.isBoom(error) ? error.output.statusCode : error.statusCode || error.status;
}
exports.getErrorStatusCode = getErrorStatusCode;

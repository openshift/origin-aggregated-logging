"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.isUninitializedLoadingResult = (loadingResult) => loadingResult.result === 'uninitialized';
exports.isSuccessLoadingResult = (loadingResult) => loadingResult.result === 'success';
exports.isFailureLoadingResult = (loadingResult) => loadingResult.result === 'failure';
exports.isExhaustedLoadingResult = (loadingResult) => exports.isSuccessLoadingResult(loadingResult) && loadingResult.isExhausted;
exports.getTimeOrDefault = (loadingResult, defaultValue) => (exports.isUninitializedLoadingResult(loadingResult) ? defaultValue || null : loadingResult.time);
exports.createSuccessResult = (parameters, isExhausted) => ({
    isExhausted,
    parameters,
    result: 'success',
    time: Date.now(),
});
exports.createSuccessResultReducer = (isExhausted) => (state, { params, result }) => exports.createSuccessResult(params, isExhausted(params, result));
exports.createFailureResult = (parameters, reason) => ({
    parameters,
    reason,
    result: 'failure',
    time: Date.now(),
});
exports.createFailureResultReducer = (convertErrorToString = error => `${error}`) => (state, { params, error }) => exports.createFailureResult(params, convertErrorToString(error));

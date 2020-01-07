"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * A handful of helper functions for testing the task manager.
 */
const sinon_1 = tslib_1.__importDefault(require("sinon"));
// Caching this here to avoid setTimeout mocking affecting our tests.
const nativeTimeout = setTimeout;
/**
 * Creates a mock task manager Logger.
 */
function mockLogger() {
    return {
        info: sinon_1.default.stub(),
        debug: sinon_1.default.stub(),
        warning: sinon_1.default.stub(),
        error: sinon_1.default.stub(),
    };
}
exports.mockLogger = mockLogger;
/**
 * Creates a promise which can be resolved externally, useful for
 * coordinating async tests.
 */
function resolvable() {
    let resolve;
    const result = new Promise(r => (resolve = r));
    result.resolve = () => nativeTimeout(resolve, 0);
    return result;
}
exports.resolvable = resolvable;
/**
 * A simple helper for waiting a specified number of milliseconds.
 *
 * @param {number} ms
 */
async function sleep(ms) {
    return new Promise(r => nativeTimeout(r, ms));
}
exports.sleep = sleep;

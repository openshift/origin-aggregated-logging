"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const isEqual_1 = tslib_1.__importDefault(require("lodash/fp/isEqual"));
function callWithoutRepeats(func, isArgsEqual = isEqual_1.default) {
    let previousArgs;
    let previousResult;
    return (...args) => {
        if (!isArgsEqual(args, previousArgs)) {
            previousArgs = args;
            previousResult = func(...args);
        }
        return previousResult;
    };
}
exports.callWithoutRepeats = callWithoutRepeats;

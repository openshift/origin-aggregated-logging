"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const joi_1 = tslib_1.__importDefault(require("joi"));
exports.validateRunResult = joi_1.default.object({
    runAt: joi_1.default.date().optional(),
    error: joi_1.default.object().optional(),
    state: joi_1.default.object().optional(),
}).optional();
exports.validateTaskDefinition = joi_1.default.object({
    type: joi_1.default.string().required(),
    title: joi_1.default.string().optional(),
    description: joi_1.default.string().optional(),
    timeout: joi_1.default.string().default('5m'),
    numWorkers: joi_1.default.number()
        .min(1)
        .default(1),
    createTaskRunner: joi_1.default.func().required(),
}).default();

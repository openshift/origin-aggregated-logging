"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const Joi = tslib_1.__importStar(require("joi"));
exports.timestampSchema = Joi.number()
    .integer()
    .min(0);
exports.logEntryFieldsMappingSchema = Joi.object().keys({
    message: Joi.string().required(),
    tiebreaker: Joi.string().required(),
    time: Joi.string().required(),
});
exports.logEntryTimeSchema = Joi.object().keys({
    tiebreaker: Joi.number().integer(),
    time: exports.timestampSchema,
});
exports.indicesSchema = Joi.array().items(Joi.string());
exports.summaryBucketSizeSchema = Joi.object().keys({
    unit: Joi.string()
        .valid(['y', 'M', 'w', 'd', 'h', 'm', 's'])
        .required(),
    value: Joi.number()
        .integer()
        .min(0)
        .required(),
});

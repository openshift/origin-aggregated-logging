"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const lodash_1 = require("lodash");
const isJsonObject = (subject) => {
    return lodash_1.isPlainObject(subject);
};
const serializeValue = (value) => {
    if (lodash_1.isArray(value) || lodash_1.isPlainObject(value)) {
        return JSON.stringify(value);
    }
    return `${value}`;
};
exports.convertDocumentSourceToLogItemFields = (source, path = [], fields = []) => {
    return Object.keys(source).reduce((acc, key) => {
        const value = source[key];
        const nextPath = [...path, key];
        if (isJsonObject(value)) {
            return exports.convertDocumentSourceToLogItemFields(value, nextPath, acc);
        }
        const field = { field: nextPath.join('.'), value: serializeValue(value) };
        return [...acc, field];
    }, fields);
};

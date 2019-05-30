"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
function toSpaceIdentifier(value = '') {
    return value.toLowerCase().replace(/[^a-z0-9_]/g, '-');
}
exports.toSpaceIdentifier = toSpaceIdentifier;
function isValidSpaceIdentifier(value = '') {
    return value === toSpaceIdentifier(value);
}
exports.isValidSpaceIdentifier = isValidSpaceIdentifier;

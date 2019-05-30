"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const lodash_1 = require("lodash");
/**
 * Returns whether the given Space is reserved or not.
 *
 * @param space the space
 * @returns boolean
 */
function isReservedSpace(space) {
    return lodash_1.get(space, '_reserved', false);
}
exports.isReservedSpace = isReservedSpace;

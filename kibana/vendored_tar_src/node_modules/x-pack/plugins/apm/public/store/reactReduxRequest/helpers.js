"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const lodash_1 = require("lodash");
const reselect_1 = require("reselect");
function createInitialDataSelector(initialData) {
    return reselect_1.createSelector(state => state, state => {
        const data = lodash_1.get(state, 'data') || initialData;
        return { ...state, data };
    });
}
exports.createInitialDataSelector = createInitialDataSelector;

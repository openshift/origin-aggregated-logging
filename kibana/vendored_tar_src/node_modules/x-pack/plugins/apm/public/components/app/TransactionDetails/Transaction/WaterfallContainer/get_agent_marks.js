"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const lodash_1 = require("lodash");
function getAgentMarks(transaction) {
    if (!(transaction.transaction.marks && transaction.transaction.marks.agent)) {
        return [];
    }
    return lodash_1.sortBy(Object.entries(transaction.transaction.marks.agent).map(([name, ms]) => ({
        name,
        us: ms * 1000
    })), 'us');
}
exports.getAgentMarks = getAgentMarks;

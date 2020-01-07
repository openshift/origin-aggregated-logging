"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
async function fetchLatestTime(search, indices, timeField) {
    const response = await search({
        allowNoIndices: true,
        body: {
            aggregations: {
                max_time: {
                    max: {
                        field: timeField,
                    },
                },
            },
            query: {
                match_all: {},
            },
            size: 0,
        },
        ignoreUnavailable: true,
        index: indices,
    });
    if (response.aggregations && response.aggregations.max_time) {
        return response.aggregations.max_time.value;
    }
    else {
        return 0;
    }
}
exports.fetchLatestTime = fetchLatestTime;

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Will convert the filter object supplied by the client
 * to use a filter rather than a must clause.
 * @param filterString The filters to apply
 */
exports.getFilterFromMust = (dateRangeStart, dateRangeEnd, filterString) => {
    let filterClauses = [
        { range: { '@timestamp': { gte: dateRangeStart, lte: dateRangeEnd } } },
    ];
    if (filterString) {
        const filters = JSON.parse(filterString);
        filterClauses = filterClauses.concat(filters.bool.must);
    }
    return {
        bool: { filter: filterClauses },
    };
};

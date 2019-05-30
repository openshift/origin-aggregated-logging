"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const invert_1 = tslib_1.__importDefault(require("lodash/fp/invert"));
const mapKeys_1 = tslib_1.__importDefault(require("lodash/fp/mapKeys"));
const elasticsearch_1 = require("./elasticsearch");
exports.convertHitToSearchResult = (fields) => {
    const invertedFields = invert_1.default(fields);
    return (hit) => {
        const matches = mapKeys_1.default(key => invertedFields[key], hit.highlight || {});
        return {
            fields: {
                tiebreaker: hit.sort[1],
                time: hit.sort[0],
            },
            gid: getHitGid(hit),
            matches,
        };
    };
};
exports.convertDateHistogramToSearchSummaryBuckets = (fields, end) => (buckets) => buckets.reduceRight(({ previousStart, aggregatedBuckets }, bucket) => {
    const representative = elasticsearch_1.isBucketWithAggregation(bucket, 'top_entries') &&
        bucket.top_entries.hits.hits.length > 0
        ? exports.convertHitToSearchResult(fields)(bucket.top_entries.hits.hits[0])
        : null;
    return {
        aggregatedBuckets: [
            ...(representative
                ? [
                    {
                        count: bucket.doc_count,
                        end: previousStart,
                        representative,
                        start: bucket.key,
                    },
                ]
                : []),
            ...aggregatedBuckets,
        ],
        previousStart: bucket.key,
    };
}, { previousStart: end, aggregatedBuckets: [] }).aggregatedBuckets;
const getHitGid = (hit) => `${hit._index}:${hit._type}:${hit._id}`;

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const Boom = tslib_1.__importStar(require("boom"));
const Joi = tslib_1.__importStar(require("joi"));
const converters_1 = require("./converters");
const schemas_1 = require("./schemas");
exports.initSearchSummaryRoutes = (framework) => {
    const callWithRequest = framework.callWithRequest;
    framework.registerRoute({
        options: {
            validate: {
                payload: Joi.object().keys({
                    bucketSize: schemas_1.summaryBucketSizeSchema.required(),
                    end: schemas_1.timestampSchema.required(),
                    fields: schemas_1.logEntryFieldsMappingSchema.required(),
                    indices: schemas_1.indicesSchema.required(),
                    query: Joi.string().required(),
                    start: schemas_1.timestampSchema.required(),
                }),
            },
        },
        handler: async (request) => {
            const timings = {
                esRequestSent: Date.now(),
                esResponseProcessed: 0,
            };
            try {
                const search = (params) => callWithRequest(request, 'search', params);
                const summaryBuckets = await fetchSummaryBuckets(search, request.payload.indices, request.payload.fields, request.payload.start, request.payload.end, request.payload.bucketSize, request.payload.query);
                timings.esResponseProcessed = Date.now();
                return {
                    buckets: summaryBuckets,
                    timings,
                };
            }
            catch (requestError) {
                throw Boom.boomify(requestError);
            }
        },
        method: 'POST',
        path: '/api/logging/search-summary',
    });
};
async function fetchSummaryBuckets(search, indices, fields, start, end, bucketSize, query) {
    const response = await search({
        allowNoIndices: true,
        body: {
            aggregations: {
                count_by_date: {
                    aggregations: {
                        top_entries: {
                            top_hits: {
                                _source: [fields.message],
                                size: 1,
                                sort: [{ [fields.time]: 'desc' }, { [fields.tiebreaker]: 'desc' }],
                            },
                        },
                    },
                    date_histogram: {
                        extended_bounds: {
                            max: end,
                            min: start,
                        },
                        field: fields.time,
                        interval: `${bucketSize.value}${bucketSize.unit}`,
                        min_doc_count: 0,
                    },
                },
            },
            query: {
                bool: {
                    filter: [
                        {
                            query_string: {
                                default_field: fields.message,
                                default_operator: 'AND',
                                query,
                            },
                        },
                        {
                            range: {
                                [fields.time]: {
                                    format: 'epoch_millis',
                                    gte: start,
                                    lt: end,
                                },
                            },
                        },
                    ],
                },
            },
            size: 0,
        },
        ignoreUnavailable: true,
        index: indices,
    });
    if (response.aggregations && response.aggregations.count_by_date) {
        return converters_1.convertDateHistogramToSearchSummaryBuckets(fields, end)(response.aggregations.count_by_date.buckets);
    }
    else {
        return [];
    }
}

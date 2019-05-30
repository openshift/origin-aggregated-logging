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
const log_entry_1 = require("../../common/log_entry");
const converters_1 = require("./converters");
const elasticsearch_1 = require("./elasticsearch");
const schemas_1 = require("./schemas");
exports.initContainedSearchResultsRoutes = (framework) => {
    const callWithRequest = framework.callWithRequest;
    framework.registerRoute({
        options: {
            validate: {
                payload: Joi.object().keys({
                    end: schemas_1.logEntryTimeSchema.required(),
                    fields: schemas_1.logEntryFieldsMappingSchema.required(),
                    indices: schemas_1.indicesSchema.required(),
                    query: Joi.string().required(),
                    start: schemas_1.logEntryTimeSchema.required(),
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
                const searchResults = await fetchSearchResultsBetween(search, request.payload.indices, request.payload.fields, request.payload.start, request.payload.end, request.payload.query);
                timings.esResponseProcessed = Date.now();
                return {
                    results: searchResults,
                    timings,
                };
            }
            catch (requestError) {
                throw Boom.boomify(requestError);
            }
        },
        method: 'POST',
        path: '/api/logging/contained-search-results',
    });
};
async function fetchSearchResultsBetween(search, indices, fields, start, end, query) {
    const request = {
        allowNoIndices: true,
        body: {
            _source: false,
            highlight: {
                boundary_scanner: 'word',
                fields: {
                    [fields.message]: {},
                },
                fragment_size: 1,
                number_of_fragments: 100,
                post_tags: [''],
                pre_tags: [''],
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
                                    gte: start.time,
                                    lte: end.time,
                                },
                            },
                        },
                    ],
                },
            },
            search_after: [start.time, start.tiebreaker - 1],
            size: 10000,
            sort: [{ [fields.time]: 'asc' }, { [fields.tiebreaker]: 'asc' }],
        },
        ignoreUnavailable: true,
        index: indices,
    };
    const response = await search(request);
    const hits = response.hits.hits;
    const filteredHits = hits
        .filter(hit => log_entry_1.isLessOrEqual({ time: hit.sort[0], tiebreaker: hit.sort[1] }, end))
        .filter(elasticsearch_1.isHighlightedHit);
    return filteredHits.map(converters_1.convertHitToSearchResult(fields));
}
exports.fetchSearchResultsBetween = fetchSearchResultsBetween;

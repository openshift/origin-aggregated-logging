"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class MemoryElasticsearchAdapter {
    constructor(mockIsKueryValid, mockKueryToEsQuery, suggestions) {
        this.mockIsKueryValid = mockIsKueryValid;
        this.mockKueryToEsQuery = mockKueryToEsQuery;
        this.suggestions = suggestions;
    }
    isKueryValid(kuery) {
        return this.mockIsKueryValid(kuery);
    }
    async convertKueryToEsQuery(kuery) {
        return this.mockKueryToEsQuery(kuery);
    }
    async getSuggestions(kuery, selectionStart) {
        return this.suggestions;
    }
}
exports.MemoryElasticsearchAdapter = MemoryElasticsearchAdapter;

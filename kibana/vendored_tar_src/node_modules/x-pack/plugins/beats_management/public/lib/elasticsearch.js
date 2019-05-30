"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class ElasticsearchLib {
    constructor(adapter) {
        this.adapter = adapter;
        this.hiddenFields = [
            { op: 'startsWith', value: 'enrollment_token' },
            { op: 'is', value: 'beat.active' },
            { op: 'is', value: 'beat.enrollment_token' },
            { op: 'is', value: 'beat.access_token' },
            { op: 'is', value: 'beat.ephemeral_id' },
            { op: 'is', value: 'beat.verified_on' },
        ];
    }
    isKueryValid(kuery) {
        return this.adapter.isKueryValid(kuery);
    }
    async convertKueryToEsQuery(kuery) {
        return await this.adapter.convertKueryToEsQuery(kuery);
    }
    async getSuggestions(kuery, selectionStart, fieldPrefix) {
        const suggestions = await this.adapter.getSuggestions(kuery, selectionStart);
        const filteredSuggestions = suggestions.filter(suggestion => {
            const hiddenFieldsCheck = this.hiddenFields;
            if (fieldPrefix) {
                hiddenFieldsCheck.push({
                    op: 'withoutPrefix',
                    value: `${fieldPrefix}.`,
                });
            }
            return hiddenFieldsCheck.reduce((isvalid, field) => {
                if (!isvalid) {
                    return false;
                }
                switch (field.op) {
                    case 'startsWith':
                        return !suggestion.text.startsWith(field.value);
                    case 'is':
                        return suggestion.text.trim() !== field.value;
                    case 'withoutPrefix':
                        return suggestion.text.startsWith(field.value);
                }
            }, true);
        });
        return filteredSuggestions;
    }
}
exports.ElasticsearchLib = ElasticsearchLib;

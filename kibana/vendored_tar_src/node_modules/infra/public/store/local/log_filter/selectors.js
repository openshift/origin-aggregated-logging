"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const reselect_1 = require("reselect");
const es_query_1 = require("@kbn/es-query");
exports.selectLogFilterQuery = (state) => state.filterQuery ? state.filterQuery.query : null;
exports.selectLogFilterQueryAsJson = (state) => state.filterQuery ? state.filterQuery.serializedQuery : null;
exports.selectLogFilterQueryDraft = (state) => state.filterQueryDraft;
exports.selectIsLogFilterQueryDraftValid = reselect_1.createSelector(exports.selectLogFilterQueryDraft, filterQueryDraft => {
    if (filterQueryDraft && filterQueryDraft.kind === 'kuery') {
        try {
            es_query_1.fromKueryExpression(filterQueryDraft.expression);
        }
        catch (err) {
            return false;
        }
    }
    return true;
});

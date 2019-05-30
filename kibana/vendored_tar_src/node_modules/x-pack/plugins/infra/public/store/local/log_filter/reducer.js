"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const dist_1 = require("typescript-fsa-reducers/dist");
const actions_1 = require("./actions");
exports.initialLogFilterState = {
    filterQuery: null,
    filterQueryDraft: null,
};
exports.logFilterReducer = dist_1.reducerWithInitialState(exports.initialLogFilterState)
    .case(actions_1.setLogFilterQueryDraft, (state, filterQueryDraft) => ({
    ...state,
    filterQueryDraft,
}))
    .case(actions_1.applyLogFilterQuery, (state, filterQuery) => ({
    ...state,
    filterQuery,
    filterQueryDraft: filterQuery.query,
}))
    .build();

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const reselect_1 = require("reselect");
const remote_graphql_state_1 = require("../../../utils/remote_state/remote_graphql_state");
const entriesGraphlStateSelectors = remote_graphql_state_1.createGraphqlStateSelectors();
exports.selectEntries = reselect_1.createSelector(entriesGraphlStateSelectors.selectData, data => (data ? data.entries : []));
exports.selectIsLoadingEntries = entriesGraphlStateSelectors.selectIsLoading;
exports.selectIsReloadingEntries = reselect_1.createSelector(entriesGraphlStateSelectors.selectIsLoading, entriesGraphlStateSelectors.selectLoadingProgressOperationInfo, (isLoading, operationInfo) => isLoading && operationInfo ? operationInfo.operationKey === 'load' : false);
exports.selectIsLoadingMoreEntries = reselect_1.createSelector(entriesGraphlStateSelectors.selectIsLoading, entriesGraphlStateSelectors.selectLoadingProgressOperationInfo, (isLoading, operationInfo) => isLoading && operationInfo ? operationInfo.operationKey === 'load_more' : false);
exports.selectEntriesStart = reselect_1.createSelector(entriesGraphlStateSelectors.selectData, data => (data && data.start ? data.start : null));
exports.selectEntriesEnd = reselect_1.createSelector(entriesGraphlStateSelectors.selectData, data => (data && data.end ? data.end : null));
exports.selectHasMoreBeforeStart = reselect_1.createSelector(entriesGraphlStateSelectors.selectData, data => (data ? data.hasMoreBefore : true));
exports.selectHasMoreAfterEnd = reselect_1.createSelector(entriesGraphlStateSelectors.selectData, data => (data ? data.hasMoreAfter : true));
exports.selectEntriesLastLoadedTime = entriesGraphlStateSelectors.selectLoadingResultTime;
exports.selectEntriesStartLoadingState = entriesGraphlStateSelectors.selectLoadingState;
exports.selectEntriesEndLoadingState = entriesGraphlStateSelectors.selectLoadingState;
exports.selectFirstEntry = reselect_1.createSelector(exports.selectEntries, entries => (entries.length > 0 ? entries[0] : null));
exports.selectLastEntry = reselect_1.createSelector(exports.selectEntries, entries => (entries.length > 0 ? entries[entries.length - 1] : null));
exports.selectLoadedEntriesTimeInterval = reselect_1.createSelector(entriesGraphlStateSelectors.selectData, data => ({
    end: data && data.end ? data.end.time : null,
    start: data && data.start ? data.start.time : null,
}));

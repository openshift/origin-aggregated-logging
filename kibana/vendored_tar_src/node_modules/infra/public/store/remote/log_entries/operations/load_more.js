"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const log_entry_1 = require("../../../../utils/log_entry");
const remote_graphql_state_1 = require("../../../../utils/remote_state/remote_graphql_state");
const state_1 = require("../state");
const log_entries_gql_query_1 = require("./log_entries.gql_query");
const operationKey = 'load_more';
exports.loadMoreEntriesActionCreators = remote_graphql_state_1.createGraphqlOperationActionCreators('log_entries', operationKey);
exports.loadMoreEntriesReducer = remote_graphql_state_1.createGraphqlOperationReducer(operationKey, state_1.initialLogEntriesState, exports.loadMoreEntriesActionCreators, (state, action) => {
    const logEntriesAround = action.payload.result.data.source.logEntriesAround;
    const newEntries = logEntriesAround.entries;
    const oldEntries = state && state.entries ? state.entries : [];
    const oldStart = state && state.start ? state.start : null;
    const oldEnd = state && state.end ? state.end : null;
    if (newEntries.length <= 0) {
        return state;
    }
    if ((action.payload.params.countBefore || 0) > 0) {
        const lastLogEntry = newEntries[newEntries.length - 1];
        const prependAtIndex = log_entry_1.getLogEntryIndexAfterTime(oldEntries, log_entry_1.getLogEntryKey(lastLogEntry));
        return {
            start: logEntriesAround.start,
            end: oldEnd,
            hasMoreBefore: logEntriesAround.hasMoreBefore,
            hasMoreAfter: state ? state.hasMoreAfter : logEntriesAround.hasMoreAfter,
            entries: [...newEntries, ...oldEntries.slice(prependAtIndex)],
        };
    }
    else if ((action.payload.params.countAfter || 0) > 0) {
        const firstLogEntry = newEntries[0];
        const appendAtIndex = log_entry_1.getLogEntryIndexBeforeTime(oldEntries, log_entry_1.getLogEntryKey(firstLogEntry));
        return {
            start: oldStart,
            end: logEntriesAround.end,
            hasMoreBefore: state ? state.hasMoreBefore : logEntriesAround.hasMoreBefore,
            hasMoreAfter: logEntriesAround.hasMoreAfter,
            entries: [...oldEntries.slice(0, appendAtIndex), ...newEntries],
        };
    }
    else {
        return state;
    }
});
exports.loadMoreEntriesEpic = remote_graphql_state_1.createGraphqlQueryEpic(log_entries_gql_query_1.logEntriesQuery, exports.loadMoreEntriesActionCreators);

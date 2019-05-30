/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
import * as tslib_1 from "tslib";
import _ from 'lodash';
import { EmbeddableActionTypeKeys, PanelActionTypeKeys, } from '../actions';
var embeddableIsInitializing = function (embeddables, panelId) {
    var _a;
    return (tslib_1.__assign({}, embeddables, (_a = {}, _a[panelId] = {
        error: undefined,
        initialized: false,
        metadata: {},
        stagedFilter: undefined,
        lastReloadRequestTime: 0,
    }, _a)));
};
var embeddableIsInitialized = function (embeddables, _a) {
    var panelId = _a.panelId, metadata = _a.metadata;
    var _b;
    return (tslib_1.__assign({}, embeddables, (_b = {}, _b[panelId] = tslib_1.__assign({}, embeddables[panelId], { initialized: true, metadata: tslib_1.__assign({}, metadata) }), _b)));
};
var setStagedFilter = function (embeddables, _a) {
    var panelId = _a.panelId, stagedFilter = _a.stagedFilter;
    var _b;
    return (tslib_1.__assign({}, embeddables, (_b = {}, _b[panelId] = tslib_1.__assign({}, embeddables[panelId], { stagedFilter: stagedFilter }), _b)));
};
var embeddableError = function (embeddables, payload) {
    var _a;
    return (tslib_1.__assign({}, embeddables, (_a = {}, _a[payload.panelId] = tslib_1.__assign({}, embeddables[payload.panelId], { error: payload.error }), _a)));
};
var clearStagedFilters = function (embeddables) {
    var omitStagedFilters = function (embeddable) {
        return _.omit(tslib_1.__assign({}, embeddable), ['stagedFilter']);
    };
    return _.mapValues(embeddables, omitStagedFilters);
};
var deleteEmbeddable = function (embeddables, panelId) {
    var embeddablesCopy = tslib_1.__assign({}, embeddables);
    delete embeddablesCopy[panelId];
    return embeddablesCopy;
};
var setReloadRequestTime = function (embeddables, lastReloadRequestTime) {
    return _.mapValues(embeddables, function (embeddable) { return (tslib_1.__assign({}, embeddable, { lastReloadRequestTime: lastReloadRequestTime })); });
};
export var embeddablesReducer = function (embeddables, action) {
    if (embeddables === void 0) { embeddables = {}; }
    switch (action.type) {
        case EmbeddableActionTypeKeys.EMBEDDABLE_IS_INITIALIZING:
            return embeddableIsInitializing(embeddables, action.payload);
        case EmbeddableActionTypeKeys.EMBEDDABLE_IS_INITIALIZED:
            return embeddableIsInitialized(embeddables, action.payload);
        case EmbeddableActionTypeKeys.SET_STAGED_FILTER:
            return setStagedFilter(embeddables, action.payload);
        case EmbeddableActionTypeKeys.CLEAR_STAGED_FILTERS:
            return clearStagedFilters(embeddables);
        case EmbeddableActionTypeKeys.EMBEDDABLE_ERROR:
            return embeddableError(embeddables, action.payload);
        case PanelActionTypeKeys.DELETE_PANEL:
            return deleteEmbeddable(embeddables, action.payload);
        case EmbeddableActionTypeKeys.REQUEST_RELOAD:
            return setReloadRequestTime(embeddables, new Date().getTime());
        default:
            return embeddables;
    }
};

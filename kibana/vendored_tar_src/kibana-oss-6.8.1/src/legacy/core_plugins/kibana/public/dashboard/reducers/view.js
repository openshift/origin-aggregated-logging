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
import { cloneDeep } from 'lodash';
import { ViewActionTypeKeys } from '../actions';
import { QueryLanguageType } from 'ui/embeddable/types';
import { DashboardViewMode } from '../dashboard_view_mode';
var closeContextMenu = function (view) { return (tslib_1.__assign({}, view, { visibleContextMenuPanelId: undefined })); };
var setVisibleContextMenuPanelId = function (view, panelId) { return (tslib_1.__assign({}, view, { visibleContextMenuPanelId: panelId })); };
var updateHidePanelTitles = function (view, hidePanelTitles) { return (tslib_1.__assign({}, view, { hidePanelTitles: hidePanelTitles })); };
var minimizePanel = function (view) { return (tslib_1.__assign({}, view, { maximizedPanelId: undefined })); };
var maximizePanel = function (view, panelId) { return (tslib_1.__assign({}, view, { maximizedPanelId: panelId })); };
var updateIsFullScreenMode = function (view, isFullScreenMode) { return (tslib_1.__assign({}, view, { isFullScreenMode: isFullScreenMode })); };
var updateTimeRange = function (view, timeRange) { return (tslib_1.__assign({}, view, { timeRange: timeRange })); };
var updateFilters = function (view, filters) { return (tslib_1.__assign({}, view, { filters: cloneDeep(filters) })); };
var updateQuery = function (view, query) { return (tslib_1.__assign({}, view, { query: query })); };
var updateUseMargins = function (view, useMargins) { return (tslib_1.__assign({}, view, { useMargins: useMargins })); };
var updateViewMode = function (view, viewMode) { return (tslib_1.__assign({}, view, { viewMode: viewMode })); };
export var viewReducer = function (view, action) {
    if (view === void 0) { view = {
        filters: [],
        hidePanelTitles: false,
        isFullScreenMode: false,
        query: { language: QueryLanguageType.LUCENE, query: '' },
        timeRange: { to: 'now', from: 'now-15m' },
        useMargins: true,
        viewMode: DashboardViewMode.VIEW,
    }; }
    switch (action.type) {
        case ViewActionTypeKeys.MINIMIZE_PANEL:
            return minimizePanel(view);
        case ViewActionTypeKeys.MAXIMIZE_PANEl:
            return maximizePanel(view, action.payload);
        case ViewActionTypeKeys.SET_VISIBLE_CONTEXT_MENU_PANEL_ID:
            return setVisibleContextMenuPanelId(view, action.payload);
        case ViewActionTypeKeys.CLOSE_CONTEXT_MENU:
            return closeContextMenu(view);
        case ViewActionTypeKeys.UPDATE_HIDE_PANEL_TITLES:
            return updateHidePanelTitles(view, action.payload);
        case ViewActionTypeKeys.UPDATE_TIME_RANGE:
            return updateTimeRange(view, action.payload);
        case ViewActionTypeKeys.UPDATE_USE_MARGINS:
            return updateUseMargins(view, action.payload);
        case ViewActionTypeKeys.UPDATE_VIEW_MODE:
            return updateViewMode(view, action.payload);
        case ViewActionTypeKeys.UPDATE_IS_FULL_SCREEN_MODE:
            return updateIsFullScreenMode(view, action.payload);
        case ViewActionTypeKeys.UPDATE_FILTERS:
            return updateFilters(view, action.payload);
        case ViewActionTypeKeys.UPDATE_QUERY:
            return updateQuery(view, action.payload);
        default:
            return view;
    }
};

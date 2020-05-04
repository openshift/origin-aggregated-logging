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
import { createAction } from 'redux-actions';
export var ViewActionTypeKeys;
(function (ViewActionTypeKeys) {
    ViewActionTypeKeys["UPDATE_VIEW_MODE"] = "UPDATE_VIEW_MODE";
    ViewActionTypeKeys["SET_VISIBLE_CONTEXT_MENU_PANEL_ID"] = "SET_VISIBLE_CONTEXT_MENU_PANEL_ID";
    ViewActionTypeKeys["MAXIMIZE_PANEl"] = "MAXIMIZE_PANEl";
    ViewActionTypeKeys["MINIMIZE_PANEL"] = "MINIMIZE_PANEL";
    ViewActionTypeKeys["UPDATE_IS_FULL_SCREEN_MODE"] = "UPDATE_IS_FULL_SCREEN_MODE";
    ViewActionTypeKeys["UPDATE_USE_MARGINS"] = "UPDATE_USE_MARGINS";
    ViewActionTypeKeys["UPDATE_HIDE_PANEL_TITLES"] = "UPDATE_HIDE_PANEL_TITLES";
    ViewActionTypeKeys["UPDATE_TIME_RANGE"] = "UPDATE_TIME_RANGE";
    ViewActionTypeKeys["UPDATE_FILTERS"] = "UPDATE_FILTERS";
    ViewActionTypeKeys["UPDATE_QUERY"] = "UPDATE_QUERY";
    ViewActionTypeKeys["CLOSE_CONTEXT_MENU"] = "CLOSE_CONTEXT_MENU";
})(ViewActionTypeKeys || (ViewActionTypeKeys = {}));
export var updateViewMode = createAction(ViewActionTypeKeys.UPDATE_VIEW_MODE);
export var closeContextMenu = createAction(ViewActionTypeKeys.CLOSE_CONTEXT_MENU);
export var setVisibleContextMenuPanelId = createAction(ViewActionTypeKeys.SET_VISIBLE_CONTEXT_MENU_PANEL_ID);
export var maximizePanel = createAction(ViewActionTypeKeys.MAXIMIZE_PANEl);
export var minimizePanel = createAction(ViewActionTypeKeys.MINIMIZE_PANEL);
export var updateIsFullScreenMode = createAction(ViewActionTypeKeys.UPDATE_IS_FULL_SCREEN_MODE);
export var updateUseMargins = createAction(ViewActionTypeKeys.UPDATE_USE_MARGINS);
export var updateHidePanelTitles = createAction(ViewActionTypeKeys.UPDATE_HIDE_PANEL_TITLES);
export var updateTimeRange = createAction(ViewActionTypeKeys.UPDATE_TIME_RANGE);
export var updateFilters = createAction(ViewActionTypeKeys.UPDATE_FILTERS);
export var updateQuery = createAction(ViewActionTypeKeys.UPDATE_QUERY);

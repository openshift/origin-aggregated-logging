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
import * as DashboardSelectors from '../dashboard/selectors';
export var getDashboard = function (state) {
    return state.dashboard;
};
export var getPanels = function (state) {
    return DashboardSelectors.getPanels(getDashboard(state));
};
export var getPanel = function (state, panelId) {
    return DashboardSelectors.getPanel(getDashboard(state), panelId);
};
export var getPanelType = function (state, panelId) {
    return DashboardSelectors.getPanelType(getDashboard(state), panelId);
};
export var getEmbeddables = function (state) {
    return DashboardSelectors.getEmbeddables(getDashboard(state));
};
export var getEmbeddableError = function (state, panelId) {
    return DashboardSelectors.getEmbeddableError(getDashboard(state), panelId);
};
export var getEmbeddableInitialized = function (state, panelId) {
    return DashboardSelectors.getEmbeddableInitialized(getDashboard(state), panelId);
};
export var getEmbeddableCustomization = function (state, panelId) {
    return DashboardSelectors.getEmbeddableCustomization(getDashboard(state), panelId);
};
export var getEmbeddableStagedFilter = function (state, panelId) {
    return DashboardSelectors.getEmbeddableStagedFilter(getDashboard(state), panelId);
};
export var getEmbeddableMetadata = function (state, panelId) {
    return DashboardSelectors.getEmbeddableMetadata(getDashboard(state), panelId);
};
export var getStagedFilters = function (state) {
    return DashboardSelectors.getStagedFilters(getDashboard(state));
};
export var getViewMode = function (state) {
    return DashboardSelectors.getViewMode(getDashboard(state));
};
export var getFullScreenMode = function (state) {
    return DashboardSelectors.getFullScreenMode(getDashboard(state));
};
export var getMaximizedPanelId = function (state) {
    return DashboardSelectors.getMaximizedPanelId(getDashboard(state));
};
export var getUseMargins = function (state) {
    return DashboardSelectors.getUseMargins(getDashboard(state));
};
export var getHidePanelTitles = function (state) {
    return DashboardSelectors.getHidePanelTitles(getDashboard(state));
};
export var getTimeRange = function (state) {
    return DashboardSelectors.getTimeRange(getDashboard(state));
};
export var getFilters = function (state) {
    return DashboardSelectors.getFilters(getDashboard(state));
};
export var getQuery = function (state) {
    return DashboardSelectors.getQuery(getDashboard(state));
};
export var getTitle = function (state) {
    return DashboardSelectors.getTitle(getDashboard(state));
};
export var getDescription = function (state) {
    return DashboardSelectors.getDescription(getDashboard(state));
};

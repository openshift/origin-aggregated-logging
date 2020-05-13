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
import _ from 'lodash';
export var getPanels = function (dashboard) { return dashboard.panels; };
export var getPanel = function (dashboard, panelId) {
    return getPanels(dashboard)[panelId];
};
export var getPanelType = function (dashboard, panelId) {
    return getPanel(dashboard, panelId).type;
};
export var getEmbeddables = function (dashboard) { return dashboard.embeddables; };
// TODO: rename panel.embeddableConfig to embeddableCustomization. Because it's on the panel that's stored on a
// dashboard, renaming this will require a migration step.
export var getEmbeddableCustomization = function (dashboard, panelId) { return getPanel(dashboard, panelId).embeddableConfig; };
export var getEmbeddable = function (dashboard, panelId) {
    return dashboard.embeddables[panelId];
};
export var getEmbeddableError = function (dashboard, panelId) { return getEmbeddable(dashboard, panelId).error; };
export var getEmbeddableTitle = function (dashboard, panelId) {
    var embeddable = getEmbeddable(dashboard, panelId);
    return embeddable && embeddable.initialized && embeddable.metadata
        ? embeddable.metadata.title
        : '';
};
export var getEmbeddableInitialized = function (dashboard, panelId) {
    return getEmbeddable(dashboard, panelId).initialized;
};
export var getEmbeddableStagedFilter = function (dashboard, panelId) { return getEmbeddable(dashboard, panelId).stagedFilter; };
export var getEmbeddableMetadata = function (dashboard, panelId) { return getEmbeddable(dashboard, panelId).metadata; };
export var getEmbeddableEditUrl = function (dashboard, panelId) {
    var embeddable = getEmbeddable(dashboard, panelId);
    return embeddable && embeddable.initialized && embeddable.metadata
        ? embeddable.metadata.editUrl
        : '';
};
export var getVisibleContextMenuPanelId = function (dashboard) {
    return dashboard.view.visibleContextMenuPanelId;
};
export var getUseMargins = function (dashboard) { return dashboard.view.useMargins; };
export var getViewMode = function (dashboard) {
    return dashboard.view.viewMode;
};
export var getFullScreenMode = function (dashboard) {
    return dashboard.view.isFullScreenMode;
};
export var getHidePanelTitles = function (dashboard) {
    return dashboard.view.hidePanelTitles;
};
export var getMaximizedPanelId = function (dashboard) {
    return dashboard.view.maximizedPanelId;
};
export var getTimeRange = function (dashboard) { return dashboard.view.timeRange; };
export var getFilters = function (dashboard) { return dashboard.view.filters; };
export var getQuery = function (dashboard) { return dashboard.view.query; };
export var getMetadata = function (dashboard) { return dashboard.metadata; };
export var getTitle = function (dashboard) { return dashboard.metadata.title; };
export var getDescription = function (dashboard) {
    return dashboard.metadata.description;
};
export var getContainerState = function (dashboard, panelId) {
    var time = getTimeRange(dashboard);
    return {
        customTitle: getPanel(dashboard, panelId).title,
        embeddableCustomization: _.cloneDeep(getEmbeddableCustomization(dashboard, panelId) || {}),
        filters: getFilters(dashboard),
        hidePanelTitles: getHidePanelTitles(dashboard),
        isPanelExpanded: getMaximizedPanelId(dashboard) === panelId,
        query: getQuery(dashboard),
        timeRange: {
            from: time.from,
            to: time.to,
        },
        viewMode: getViewMode(dashboard),
    };
};
/**
 * @return an array of filters any embeddables wish dashboard to apply
 */
export var getStagedFilters = function (dashboard) {
    return _.compact(_.map(dashboard.embeddables, 'stagedFilter'));
};

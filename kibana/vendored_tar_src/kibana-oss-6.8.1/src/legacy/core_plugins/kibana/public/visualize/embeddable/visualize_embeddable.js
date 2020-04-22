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
import { Embeddable } from 'ui/embeddable';
import { PersistedState } from 'ui/persisted_state';
var VisualizeEmbeddable = /** @class */ (function (_super) {
    tslib_1.__extends(VisualizeEmbeddable, _super);
    function VisualizeEmbeddable(_a) {
        var onEmbeddableStateChanged = _a.onEmbeddableStateChanged, savedVisualization = _a.savedVisualization, editUrl = _a.editUrl, loader = _a.loader;
        var _this = _super.call(this, {
            title: savedVisualization.title,
            editUrl: editUrl,
            indexPattern: savedVisualization.vis.indexPattern,
        }) || this;
        _this.uiStateChangeHandler = function () {
            _this.customization = _this.uiState.toJSON();
            _this.onEmbeddableStateChanged(_this.getEmbeddableState());
        };
        _this.onEmbeddableStateChanged = onEmbeddableStateChanged;
        _this.savedVisualization = savedVisualization;
        _this.loader = loader;
        var parsedUiState = savedVisualization.uiStateJSON
            ? JSON.parse(savedVisualization.uiStateJSON)
            : {};
        _this.uiState = new PersistedState(parsedUiState);
        _this.uiState.on('change', _this.uiStateChangeHandler);
        return _this;
    }
    VisualizeEmbeddable.prototype.getInspectorAdapters = function () {
        if (!this.handler) {
            return undefined;
        }
        return this.handler.inspectorAdapters;
    };
    VisualizeEmbeddable.prototype.getEmbeddableState = function () {
        return {
            customization: this.customization,
        };
    };
    /**
     * Transfers all changes in the containerState.embeddableCustomization into
     * the uiState of this visualization.
     */
    VisualizeEmbeddable.prototype.transferCustomizationsToUiState = function (containerState) {
        var _this = this;
        // Check for changes that need to be forwarded to the uiState
        // Since the vis has an own listener on the uiState we don't need to
        // pass anything from here to the handler.update method
        var customization = containerState.embeddableCustomization;
        if (customization && !_.isEqual(this.customization, customization)) {
            // Turn this off or the uiStateChangeHandler will fire for every modification.
            this.uiState.off('change', this.uiStateChangeHandler);
            this.uiState.clearAllKeys();
            Object.getOwnPropertyNames(customization).forEach(function (key) {
                _this.uiState.set(key, customization[key]);
            });
            this.customization = customization;
            this.uiState.on('change', this.uiStateChangeHandler);
        }
    };
    VisualizeEmbeddable.prototype.onContainerStateChanged = function (containerState) {
        this.transferCustomizationsToUiState(containerState);
        var updatedParams = {};
        // Check if timerange has changed
        if (containerState.timeRange !== this.timeRange) {
            updatedParams.timeRange = containerState.timeRange;
            this.timeRange = containerState.timeRange;
        }
        // Check if filters has changed
        if (containerState.filters !== this.filters) {
            updatedParams.filters = containerState.filters;
            this.filters = containerState.filters;
        }
        // Check if query has changed
        if (containerState.query !== this.query) {
            updatedParams.query = containerState.query;
            this.query = containerState.query;
        }
        var derivedPanelTitle = this.getPanelTitle(containerState);
        if (this.panelTitle !== derivedPanelTitle) {
            updatedParams.dataAttrs = {
                title: derivedPanelTitle,
            };
            this.panelTitle = derivedPanelTitle;
        }
        if (this.handler && !_.isEmpty(updatedParams)) {
            this.handler.update(updatedParams);
        }
    };
    /**
     *
     * @param {Element} domNode
     * @param {ContainerState} containerState
     */
    VisualizeEmbeddable.prototype.render = function (domNode, containerState) {
        this.panelTitle = this.getPanelTitle(containerState);
        this.timeRange = containerState.timeRange;
        this.query = containerState.query;
        this.filters = containerState.filters;
        this.transferCustomizationsToUiState(containerState);
        var dataAttrs = {
            'shared-item': '',
            title: this.panelTitle,
        };
        if (this.savedVisualization.description) {
            dataAttrs.description = this.savedVisualization.description;
        }
        var handlerParams = {
            uiState: this.uiState,
            // Append visualization to container instead of replacing its content
            append: true,
            timeRange: containerState.timeRange,
            query: containerState.query,
            filters: containerState.filters,
            cssClass: "panel-content panel-content--fullWidth",
            dataAttrs: dataAttrs,
        };
        this.handler = this.loader.embedVisualizationWithSavedObject(domNode, this.savedVisualization, handlerParams);
    };
    VisualizeEmbeddable.prototype.destroy = function () {
        this.uiState.off('change', this.uiStateChangeHandler);
        this.savedVisualization.destroy();
        if (this.handler) {
            this.handler.destroy();
            this.handler.getElement().remove();
        }
    };
    VisualizeEmbeddable.prototype.reload = function () {
        if (this.handler) {
            this.handler.reload();
        }
    };
    /**
     * Retrieve the panel title for this panel from the container state.
     * This will either return the overwritten panel title or the visualization title.
     */
    VisualizeEmbeddable.prototype.getPanelTitle = function (containerState) {
        var derivedPanelTitle = '';
        if (!containerState.hidePanelTitles) {
            derivedPanelTitle =
                containerState.customTitle !== undefined
                    ? containerState.customTitle
                    : this.savedVisualization.title;
        }
        return derivedPanelTitle;
    };
    return VisualizeEmbeddable;
}(Embeddable));
export { VisualizeEmbeddable };

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
import { createAction } from 'redux-actions';
import { getEmbeddableCustomization, getPanel } from '../../selectors';
import { updatePanel } from './panels';
export var EmbeddableActionTypeKeys;
(function (EmbeddableActionTypeKeys) {
    EmbeddableActionTypeKeys["EMBEDDABLE_IS_INITIALIZING"] = "EMBEDDABLE_IS_INITIALIZING";
    EmbeddableActionTypeKeys["EMBEDDABLE_IS_INITIALIZED"] = "EMBEDDABLE_IS_INITIALIZED";
    EmbeddableActionTypeKeys["SET_STAGED_FILTER"] = "SET_STAGED_FILTER";
    EmbeddableActionTypeKeys["CLEAR_STAGED_FILTERS"] = "CLEAR_STAGED_FILTERS";
    EmbeddableActionTypeKeys["EMBEDDABLE_ERROR"] = "EMBEDDABLE_ERROR";
    EmbeddableActionTypeKeys["REQUEST_RELOAD"] = "REQUEST_RELOAD";
})(EmbeddableActionTypeKeys || (EmbeddableActionTypeKeys = {}));
export var embeddableIsInitializing = createAction(EmbeddableActionTypeKeys.EMBEDDABLE_IS_INITIALIZING);
export var embeddableIsInitialized = createAction(EmbeddableActionTypeKeys.EMBEDDABLE_IS_INITIALIZED);
export var setStagedFilter = createAction(EmbeddableActionTypeKeys.SET_STAGED_FILTER);
export var clearStagedFilters = createAction(EmbeddableActionTypeKeys.CLEAR_STAGED_FILTERS);
export var embeddableError = createAction(EmbeddableActionTypeKeys.EMBEDDABLE_ERROR);
export var requestReload = createAction(EmbeddableActionTypeKeys.REQUEST_RELOAD);
/**
 * The main point of communication from the embeddable to the dashboard. Any time state in the embeddable
 * changes, this function will be called. The data is then extracted from EmbeddableState and stored in
 * redux so the appropriate actions are taken and UI updated.
 *
 * @param changeData.panelId - the id of the panel whose state has changed.
 * @param changeData.embeddableState - the new state of the embeddable.
 */
export function embeddableStateChanged(changeData) {
    var panelId = changeData.panelId, embeddableState = changeData.embeddableState;
    return function (dispatch, getState) {
        // Translate embeddableState to things redux cares about.
        var customization = getEmbeddableCustomization(getState(), panelId);
        if (!_.isEqual(embeddableState.customization, customization)) {
            var originalPanelState = getPanel(getState(), panelId);
            var newPanelState = tslib_1.__assign({}, originalPanelState, { embeddableConfig: _.cloneDeep(embeddableState.customization) });
            dispatch(updatePanel(newPanelState));
        }
        if (embeddableState.stagedFilter) {
            dispatch(setStagedFilter({ stagedFilter: embeddableState.stagedFilter, panelId: panelId }));
        }
    };
}

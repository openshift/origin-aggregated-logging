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
import { PanelActionTypeKeys } from '../actions';
var deletePanel = function (panels, panelId) {
    var panelsCopy = tslib_1.__assign({}, panels);
    delete panelsCopy[panelId];
    return panelsCopy;
};
var updatePanel = function (panels, panelState) {
    var _a;
    return (tslib_1.__assign({}, panels, (_a = {}, _a[panelState.panelIndex] = panelState, _a)));
};
var updatePanels = function (panels, updatedPanels) {
    var panelsCopy = tslib_1.__assign({}, panels);
    Object.values(updatedPanels).forEach(function (panel) {
        panelsCopy[panel.panelIndex] = panel;
    });
    return panelsCopy;
};
var resetPanelTitle = function (panels, panelId) {
    var _a;
    return (tslib_1.__assign({}, panels, (_a = {}, _a[panelId] = tslib_1.__assign({}, panels[panelId], { title: undefined }), _a)));
};
var setPanelTitle = function (panels, payload) {
    var _a;
    return (tslib_1.__assign({}, panels, (_a = {}, _a[payload.panelId] = tslib_1.__assign({}, panels[payload.panelId], { title: payload.title }), _a)));
};
var setPanels = function (panels, newPanels) { return _.cloneDeep(newPanels); };
export var panelsReducer = function (panels, action) {
    if (panels === void 0) { panels = {}; }
    switch (action.type) {
        case PanelActionTypeKeys.DELETE_PANEL:
            return deletePanel(panels, action.payload);
        case PanelActionTypeKeys.UPDATE_PANEL:
            return updatePanel(panels, action.payload);
        case PanelActionTypeKeys.UPDATE_PANELS:
            return updatePanels(panels, action.payload);
        case PanelActionTypeKeys.RESET_PANEl_TITLE:
            return resetPanelTitle(panels, action.payload);
        case PanelActionTypeKeys.SET_PANEl_TITLE:
            return setPanelTitle(panels, action.payload);
        case PanelActionTypeKeys.SET_PANELS:
            return setPanels(panels, action.payload);
        default:
            return panels;
    }
};

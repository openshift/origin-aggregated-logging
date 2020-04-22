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
import { connect } from 'react-redux';
import { DashboardViewMode } from '../../dashboard_view_mode';
import { PanelHeader } from './panel_header';
import { getEmbeddableTitle, getFullScreenMode, getHidePanelTitles, getMaximizedPanelId, getPanel, getViewMode, } from '../../selectors';
var mapStateToProps = function (_a, _b) {
    var dashboard = _a.dashboard;
    var panelId = _b.panelId;
    var panel = getPanel(dashboard, panelId);
    var embeddableTitle = getEmbeddableTitle(dashboard, panelId);
    return {
        title: panel.title === undefined ? embeddableTitle : panel.title,
        isExpanded: getMaximizedPanelId(dashboard) === panelId,
        isViewOnlyMode: getFullScreenMode(dashboard) || getViewMode(dashboard) === DashboardViewMode.VIEW,
        hidePanelTitles: getHidePanelTitles(dashboard),
    };
};
export var PanelHeaderContainer = connect(mapStateToProps)(PanelHeader);

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
import { i18n } from '@kbn/i18n';
import { connect } from 'react-redux';
import { buildEuiContextMenuPanels, ContextMenuPanel, } from 'ui/embeddable';
import { panelActionsStore } from '../../store/panel_actions_store';
import { getCustomizePanelAction, getEditPanelAction, getInspectorPanelAction, getRemovePanelAction, getToggleExpandPanelAction, } from './panel_actions';
import { PanelOptionsMenu } from './panel_options_menu';
import { closeContextMenu, deletePanel, maximizePanel, minimizePanel, resetPanelTitle, setPanelTitle, setVisibleContextMenuPanelId, } from '../../actions';
import { DashboardViewMode } from '../../dashboard_view_mode';
import { getContainerState, getEmbeddable, getEmbeddableEditUrl, getEmbeddableTitle, getMaximizedPanelId, getPanel, getViewMode, getVisibleContextMenuPanelId, } from '../../selectors';
var mapStateToProps = function (_a, _b) {
    var dashboard = _a.dashboard;
    var panelId = _b.panelId;
    var embeddable = getEmbeddable(dashboard, panelId);
    var panel = getPanel(dashboard, panelId);
    var embeddableTitle = getEmbeddableTitle(dashboard, panelId);
    var containerState = getContainerState(dashboard, panelId);
    var visibleContextMenuPanelId = getVisibleContextMenuPanelId(dashboard);
    var viewMode = getViewMode(dashboard);
    return {
        panelTitle: panel.title === undefined ? embeddableTitle : panel.title,
        editUrl: embeddable ? getEmbeddableEditUrl(dashboard, panelId) : null,
        isExpanded: getMaximizedPanelId(dashboard) === panelId,
        containerState: containerState,
        visibleContextMenuPanelId: visibleContextMenuPanelId,
        isViewMode: viewMode === DashboardViewMode.VIEW,
    };
};
/**
 * @param dispatch {Function}
 * @param embeddableFactory {EmbeddableFactory}
 * @param panelId {string}
 */
var mapDispatchToProps = function (dispatch, _a) {
    var panelId = _a.panelId;
    return ({
        onDeletePanel: function () {
            dispatch(deletePanel(panelId));
        },
        onCloseContextMenu: function () { return dispatch(closeContextMenu()); },
        openContextMenu: function () { return dispatch(setVisibleContextMenuPanelId(panelId)); },
        onMaximizePanel: function () { return dispatch(maximizePanel(panelId)); },
        onMinimizePanel: function () { return dispatch(minimizePanel()); },
        onResetPanelTitle: function () { return dispatch(resetPanelTitle(panelId)); },
        onUpdatePanelTitle: function (newTitle) { return dispatch(setPanelTitle({ title: newTitle, panelId: panelId })); },
    });
};
var mergeProps = function (stateProps, dispatchProps, ownProps) {
    var isExpanded = stateProps.isExpanded, panelTitle = stateProps.panelTitle, containerState = stateProps.containerState, visibleContextMenuPanelId = stateProps.visibleContextMenuPanelId, isViewMode = stateProps.isViewMode;
    var isPopoverOpen = visibleContextMenuPanelId === ownProps.panelId;
    var onMaximizePanel = dispatchProps.onMaximizePanel, onMinimizePanel = dispatchProps.onMinimizePanel, onDeletePanel = dispatchProps.onDeletePanel, onResetPanelTitle = dispatchProps.onResetPanelTitle, onUpdatePanelTitle = dispatchProps.onUpdatePanelTitle, onCloseContextMenu = dispatchProps.onCloseContextMenu, openContextMenu = dispatchProps.openContextMenu;
    var toggleContextMenu = function () { return (isPopoverOpen ? onCloseContextMenu() : openContextMenu()); };
    // Outside click handlers will trigger for every closed context menu, we only want to react to clicks external to
    // the currently opened menu.
    var closeMyContextMenuPanel = function () {
        if (isPopoverOpen) {
            onCloseContextMenu();
        }
    };
    var toggleExpandedPanel = function () {
        isExpanded ? onMinimizePanel() : onMaximizePanel();
        closeMyContextMenuPanel();
    };
    var panels = [];
    // Don't build the panels if the pop over is not open, or this gets expensive - this function is called once for
    // every panel, every time any state changes.
    if (isPopoverOpen) {
        var contextMenuPanel = new ContextMenuPanel({
            title: i18n.translate('kbn.dashboard.panel.optionsMenu.optionsContextMenuTitle', {
                defaultMessage: 'Options',
            }),
            id: 'mainMenu',
        });
        var actions = [
            getInspectorPanelAction({
                closeContextMenu: closeMyContextMenuPanel,
                panelTitle: panelTitle,
            }),
            getEditPanelAction(),
            getCustomizePanelAction({
                onResetPanelTitle: onResetPanelTitle,
                onUpdatePanelTitle: onUpdatePanelTitle,
                title: panelTitle,
                closeContextMenu: closeMyContextMenuPanel,
            }),
            getToggleExpandPanelAction({ isExpanded: isExpanded, toggleExpandedPanel: toggleExpandedPanel }),
            getRemovePanelAction(onDeletePanel),
        ].concat(panelActionsStore.actions);
        panels = buildEuiContextMenuPanels({
            contextMenuPanel: contextMenuPanel,
            actions: actions,
            embeddable: ownProps.embeddable,
            containerState: containerState,
        });
    }
    return {
        panels: panels,
        toggleContextMenu: toggleContextMenu,
        closeContextMenu: closeMyContextMenuPanel,
        isPopoverOpen: isPopoverOpen,
        isViewMode: isViewMode,
    };
};
export var PanelOptionsMenuContainer = connect(mapStateToProps, mapDispatchToProps, mergeProps)(PanelOptionsMenu);

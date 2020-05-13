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
/**
 * Loops through allActions and extracts those that belong on the given contextMenuPanelId
 * @param {string} contextMenuPanelId
 * @param {Array.<ContextMenuAction>} allActions
 */
function getActionsForPanel(contextMenuPanelId, allActions) {
    return allActions.filter(function (action) { return action.parentPanelId === contextMenuPanelId; });
}
/**
 * @param {String} contextMenuPanelId
 * @param {Array.<ContextMenuAction>} actions
 * @param {Embeddable} embeddable
 * @param {ContainerState} containerState
 * @return {{
 *   Array.<EuiContextMenuPanelItemDescriptor> items - panel actions converted into the items expected to be on an
 *     EuiContextMenuPanel,
 *   Array.<EuiContextMenuPanelDescriptor> childPanels - extracted child panels, if any actions also open a panel. They
 *     need to be moved to the top level for EUI.
 *  }}
 */
function buildEuiContextMenuPanelItemsAndChildPanels(_a) {
    var contextMenuPanelId = _a.contextMenuPanelId, actions = _a.actions, embeddable = _a.embeddable, containerState = _a.containerState;
    var items = [];
    var childPanels = [];
    var actionsForPanel = getActionsForPanel(contextMenuPanelId, actions);
    actionsForPanel.forEach(function (action) {
        var isVisible = action.isVisible({ embeddable: embeddable, containerState: containerState });
        if (!isVisible) {
            return;
        }
        if (action.childContextMenuPanel) {
            childPanels.push.apply(childPanels, tslib_1.__spread(buildEuiContextMenuPanels({
                contextMenuPanel: action.childContextMenuPanel,
                actions: actions,
                embeddable: embeddable,
                containerState: containerState,
            })));
        }
        items.push(convertPanelActionToContextMenuItem({
            action: action,
            containerState: containerState,
            embeddable: embeddable,
        }));
    });
    return { items: items, childPanels: childPanels };
}
/**
 * Transforms a DashboardContextMenuPanel to the shape EuiContextMenuPanel expects, inserting any registered pluggable
 * panel actions.
 * @param {ContextMenuPanel} contextMenuPanel
 * @param {Array.<ContextMenuAction>} actions to build the context menu with
 * @param {Embeddable} embeddable
 * @param {ContainerState} containerState
 * @return {EuiContextMenuPanelDescriptor[]} An array of context menu panels to be used in the eui react component.
 */
export function buildEuiContextMenuPanels(_a) {
    var contextMenuPanel = _a.contextMenuPanel, actions = _a.actions, embeddable = _a.embeddable, containerState = _a.containerState;
    var euiContextMenuPanel = {
        id: contextMenuPanel.id,
        title: contextMenuPanel.title,
        items: [],
        content: contextMenuPanel.getContent({ embeddable: embeddable, containerState: containerState }),
    };
    var contextMenuPanels = [euiContextMenuPanel];
    var _b = buildEuiContextMenuPanelItemsAndChildPanels({
        contextMenuPanelId: contextMenuPanel.id,
        actions: actions,
        embeddable: embeddable,
        containerState: containerState,
    }), items = _b.items, childPanels = _b.childPanels;
    euiContextMenuPanel.items = items;
    return contextMenuPanels.concat(childPanels);
}
/**
 *
 * @param {ContextMenuAction} action
 * @param {ContainerState} containerState
 * @param {Embeddable} embeddable
 * @return {EuiContextMenuPanelItemDescriptor}
 */
function convertPanelActionToContextMenuItem(_a) {
    var action = _a.action, containerState = _a.containerState, embeddable = _a.embeddable;
    var menuPanelItem = {
        name: action.displayName,
        icon: action.icon,
        panel: _.get(action, 'childContextMenuPanel.id'),
        disabled: action.isDisabled({ embeddable: embeddable, containerState: containerState }),
        'data-test-subj': "dashboardPanelAction-" + action.id,
    };
    if (action.onClick) {
        menuPanelItem.onClick = function () {
            if (action.onClick) {
                action.onClick({ embeddable: embeddable, containerState: containerState });
            }
        };
    }
    if (action.getHref) {
        menuPanelItem.href = action.getHref({ embeddable: embeddable, containerState: containerState });
    }
    return menuPanelItem;
}

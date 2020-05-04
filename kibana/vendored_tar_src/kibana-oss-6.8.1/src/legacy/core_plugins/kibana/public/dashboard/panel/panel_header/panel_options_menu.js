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
import { injectI18n } from '@kbn/i18n/react';
import React from 'react';
import { EuiButtonIcon, EuiContextMenu, EuiPopover, } from '@elastic/eui';
function PanelOptionsMenuUi(_a) {
    var toggleContextMenu = _a.toggleContextMenu, isPopoverOpen = _a.isPopoverOpen, closeContextMenu = _a.closeContextMenu, panels = _a.panels, isViewMode = _a.isViewMode, intl = _a.intl;
    var button = (React.createElement(EuiButtonIcon, { iconType: isViewMode ? 'boxesHorizontal' : 'gear', color: "text", className: isViewMode && !isPopoverOpen ? 'dshPanel_optionsMenuButton' : '', "aria-label": intl.formatMessage({
            id: 'kbn.dashboard.panel.optionsMenu.panelOptionsButtonAriaLabel',
            defaultMessage: 'Panel options',
        }), "data-test-subj": "dashboardPanelToggleMenuIcon", onClick: toggleContextMenu }));
    return (React.createElement(EuiPopover, { id: "dashboardPanelContextMenu", className: "dshPanel_optionsMenuPopover", button: button, isOpen: isPopoverOpen, closePopover: closeContextMenu, panelPaddingSize: "none", anchorPosition: "downRight", "data-test-subj": isPopoverOpen ? 'dashboardPanelContextMenuOpen' : 'dashboardPanelContextMenuClosed', withTitle: true },
        React.createElement(EuiContextMenu, { initialPanelId: "mainMenu", panels: panels })));
}
export var PanelOptionsMenu = injectI18n(PanelOptionsMenuUi);

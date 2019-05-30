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
import React, { Component } from 'react';
import './share_panel_content.less';
import { EuiContextMenu } from '@elastic/eui';
import { injectI18n } from '@kbn/i18n/react';
import { UrlPanelContent } from './url_panel_content';
var ShareContextMenuUI = /** @class */ (function (_super) {
    tslib_1.__extends(ShareContextMenuUI, _super);
    function ShareContextMenuUI() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.getPanels = function () {
            var panels = [];
            var menuItems = [];
            var intl = _this.props.intl;
            var permalinkPanel = {
                id: panels.length + 1,
                title: intl.formatMessage({
                    id: 'common.ui.share.contextMenu.permalinkPanelTitle',
                    defaultMessage: 'Permalink',
                }),
                content: (React.createElement(UrlPanelContent, { objectId: _this.props.objectId, objectType: _this.props.objectType, getUnhashableStates: _this.props.getUnhashableStates })),
            };
            menuItems.push({
                name: intl.formatMessage({
                    id: 'common.ui.share.contextMenu.permalinksLabel',
                    defaultMessage: 'Permalinks',
                }),
                icon: 'link',
                panel: permalinkPanel.id,
                sortOrder: 0,
            });
            panels.push(permalinkPanel);
            if (_this.props.allowEmbed) {
                var embedPanel = {
                    id: panels.length + 1,
                    title: intl.formatMessage({
                        id: 'common.ui.share.contextMenu.embedCodePanelTitle',
                        defaultMessage: 'Embed Code',
                    }),
                    content: (React.createElement(UrlPanelContent, { isEmbedded: true, objectId: _this.props.objectId, objectType: _this.props.objectType, getUnhashableStates: _this.props.getUnhashableStates })),
                };
                panels.push(embedPanel);
                menuItems.push({
                    name: intl.formatMessage({
                        id: 'common.ui.share.contextMenu.embedCodeLabel',
                        defaultMessage: 'Embed code',
                    }),
                    icon: 'console',
                    panel: embedPanel.id,
                    sortOrder: 0,
                });
            }
            if (_this.props.shareContextMenuExtensions) {
                var _a = _this.props, objectType_1 = _a.objectType, objectId_1 = _a.objectId, getUnhashableStates_1 = _a.getUnhashableStates, sharingData_1 = _a.sharingData, isDirty_1 = _a.isDirty, onClose_1 = _a.onClose;
                _this.props.shareContextMenuExtensions.forEach(function (provider) {
                    provider
                        .getShareActions({
                        objectType: objectType_1,
                        objectId: objectId_1,
                        getUnhashableStates: getUnhashableStates_1,
                        sharingData: sharingData_1,
                        isDirty: isDirty_1,
                        onClose: onClose_1,
                    })
                        .forEach(function (_a) {
                        var shareMenuItem = _a.shareMenuItem, panel = _a.panel;
                        var panelId = panels.length + 1;
                        panels.push(tslib_1.__assign({}, panel, { id: panelId }));
                        menuItems.push(tslib_1.__assign({}, shareMenuItem, { panel: panelId }));
                    });
                });
            }
            if (menuItems.length > 1) {
                var topLevelMenuPanel = {
                    id: panels.length + 1,
                    title: intl.formatMessage({
                        id: 'common.ui.share.contextMenuTitle',
                        defaultMessage: 'Share this {objectType}',
                    }, {
                        objectType: _this.props.objectType,
                    }),
                    items: menuItems
                        // Sorts ascending on sort order first and then ascending on name
                        .sort(function (a, b) {
                        var aSortOrder = a.sortOrder || 0;
                        var bSortOrder = b.sortOrder || 0;
                        if (aSortOrder > bSortOrder) {
                            return 1;
                        }
                        if (aSortOrder < bSortOrder) {
                            return -1;
                        }
                        if (a.name.toLowerCase().localeCompare(b.name.toLowerCase()) > 0) {
                            return 1;
                        }
                        return -1;
                    })
                        .map(function (menuItem) {
                        menuItem['data-test-subj'] = "sharePanel-" + menuItem.name.replace(' ', '');
                        delete menuItem.sortOrder;
                        return menuItem;
                    }),
                };
                panels.push(topLevelMenuPanel);
            }
            var lastPanelIndex = panels.length - 1;
            var initialPanelId = panels[lastPanelIndex].id;
            return { panels: panels, initialPanelId: initialPanelId };
        };
        return _this;
    }
    ShareContextMenuUI.prototype.render = function () {
        var _a = this.getPanels(), panels = _a.panels, initialPanelId = _a.initialPanelId;
        return (React.createElement(EuiContextMenu, { initialPanelId: initialPanelId, panels: panels, "data-test-subj": "shareContextMenu" }));
    };
    return ShareContextMenuUI;
}(Component));
export var ShareContextMenu = injectI18n(ShareContextMenuUI);

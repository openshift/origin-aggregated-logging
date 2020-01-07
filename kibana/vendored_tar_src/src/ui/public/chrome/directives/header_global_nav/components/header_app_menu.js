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
import { 
// TODO: add type annotations
// @ts-ignore
EuiHeaderSectionItemButton, 
// @ts-ignore
EuiIcon, 
// @ts-ignore
EuiKeyPadMenu, 
// @ts-ignore
EuiKeyPadMenuItem, EuiPopover, } from '@elastic/eui';
import { injectI18n } from '@kbn/i18n/react';
var HeaderAppMenuUI = /** @class */ (function (_super) {
    tslib_1.__extends(HeaderAppMenuUI, _super);
    function HeaderAppMenuUI(props) {
        var _this = _super.call(this, props) || this;
        _this.onMenuButtonClick = function () {
            _this.setState({
                isOpen: !_this.state.isOpen,
            });
        };
        _this.closeMenu = function () {
            _this.setState({
                isOpen: false,
            });
        };
        _this.renderNavLink = function (navLink) { return (React.createElement(EuiKeyPadMenuItem, { label: navLink.title, href: navLink.url, key: navLink.id, onClick: _this.closeMenu },
            React.createElement(EuiIcon, { type: navLink.euiIconType, size: "l" }))); };
        _this.state = {
            isOpen: false,
        };
        return _this;
    }
    HeaderAppMenuUI.prototype.render = function () {
        var _a = this.props, _b = _a.navLinks, navLinks = _b === void 0 ? [] : _b, intl = _a.intl;
        var button = (React.createElement(EuiHeaderSectionItemButton, { "aria-controls": "keyPadMenu", "aria-expanded": this.state.isOpen, "aria-haspopup": "true", "aria-label": intl.formatMessage({
                id: 'common.ui.chrome.headerGlobalNav.appMenuButtonAriaLabel',
                defaultMessage: 'Apps menu',
            }), onClick: this.onMenuButtonClick },
            React.createElement(EuiIcon, { type: "apps", size: "m" })));
        return (React.createElement(EuiPopover, { id: "headerAppMenu", button: button, isOpen: this.state.isOpen, anchorPosition: "downRight", 
            // @ts-ignore
            repositionOnScroll: true, closePopover: this.closeMenu },
            React.createElement(EuiKeyPadMenu, { id: "keyPadMenu", style: { width: 288 } }, navLinks.map(this.renderNavLink))));
    };
    return HeaderAppMenuUI;
}(Component));
export var HeaderAppMenu = injectI18n(HeaderAppMenuUI);

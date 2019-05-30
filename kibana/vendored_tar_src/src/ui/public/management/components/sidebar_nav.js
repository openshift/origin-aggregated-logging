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
import { EuiIcon, EuiSideNav } from '@elastic/eui';
import { FormattedMessage } from '@kbn/i18n/react';
import React from 'react';
var sectionVisible = function (section) { return !section.disabled && section.visible; };
var sectionToNav = function (selectedId) { return function (_a) {
    var display = _a.display, id = _a.id, url = _a.url, icon = _a.icon;
    return ({
        id: id,
        name: display,
        icon: icon ? React.createElement(EuiIcon, { type: icon }) : null,
        isSelected: selectedId === id,
        href: url,
        'data-test-subj': id,
    });
}; };
export var sideNavItems = function (sections, selectedId) {
    return sections
        .filter(sectionVisible)
        .filter(function (section) { return section.items.filter(sectionVisible).length; })
        .map(function (section) { return (tslib_1.__assign({ items: section.items.inOrder.filter(sectionVisible).map(sectionToNav(selectedId)) }, sectionToNav(selectedId)(section))); });
};
var SidebarNav = /** @class */ (function (_super) {
    tslib_1.__extends(SidebarNav, _super);
    function SidebarNav(props) {
        var _this = _super.call(this, props) || this;
        _this.toggleOpenOnMobile = function () {
            _this.setState({
                isSideNavOpenOnMobile: !_this.state.isSideNavOpenOnMobile,
            });
        };
        _this.state = {
            isSideNavOpenOnMobile: false,
        };
        return _this;
    }
    SidebarNav.prototype.render = function () {
        return (React.createElement(EuiSideNav, { mobileTitle: this.renderMobileTitle(), isOpenOnMobile: this.state.isSideNavOpenOnMobile, toggleOpenOnMobile: this.toggleOpenOnMobile, items: sideNavItems(this.props.sections, this.props.selectedId), className: "mgtSideBarNav" }));
    };
    SidebarNav.prototype.renderMobileTitle = function () {
        return React.createElement(FormattedMessage, { id: "common.ui.management.nav.menu", defaultMessage: "Management menu" });
    };
    return SidebarNav;
}(React.Component));
export { SidebarNav };

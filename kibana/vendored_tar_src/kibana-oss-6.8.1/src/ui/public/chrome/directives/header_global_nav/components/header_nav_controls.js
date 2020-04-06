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
// @ts-ignore
EuiHeaderSectionItem, } from '@elastic/eui';
import { HeaderNavControl } from './header_nav_control';
var HeaderNavControls = /** @class */ (function (_super) {
    tslib_1.__extends(HeaderNavControls, _super);
    function HeaderNavControls() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.renderNavControl = function (navControl) { return (React.createElement(EuiHeaderSectionItem, { key: navControl.name, border: navControl.side === 'left' ? 'right' : 'left' },
            React.createElement(HeaderNavControl, { navControl: navControl }))); };
        return _this;
    }
    HeaderNavControls.prototype.render = function () {
        var navControls = this.props.navControls;
        if (!navControls) {
            return null;
        }
        return navControls.map(this.renderNavControl);
    };
    return HeaderNavControls;
}(Component));
export { HeaderNavControls };

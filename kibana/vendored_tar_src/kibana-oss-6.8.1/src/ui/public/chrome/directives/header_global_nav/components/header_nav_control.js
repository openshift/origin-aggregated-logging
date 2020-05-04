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
import React from 'react';
var HeaderNavControl = /** @class */ (function (_super) {
    tslib_1.__extends(HeaderNavControl, _super);
    function HeaderNavControl() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.ref = React.createRef();
        return _this;
    }
    HeaderNavControl.prototype.componentDidMount = function () {
        if (!this.ref.current) {
            throw new Error('<NavControl /> mounted without ref');
        }
        this.unrender = this.props.navControl.render(this.ref.current) || undefined;
    };
    HeaderNavControl.prototype.componentDidUpdate = function (prevProps) {
        if (this.props.navControl.render === prevProps.navControl.render) {
            return;
        }
        if (!this.ref.current) {
            throw new Error('<NavControl /> updated without ref');
        }
        if (this.unrender) {
            this.unrender();
        }
        this.unrender = this.props.navControl.render(this.ref.current) || undefined;
    };
    HeaderNavControl.prototype.componentWillUnmount = function () {
        if (this.unrender) {
            this.unrender();
        }
    };
    HeaderNavControl.prototype.render = function () {
        return React.createElement("div", { ref: this.ref });
    };
    return HeaderNavControl;
}(React.Component));
export { HeaderNavControl };

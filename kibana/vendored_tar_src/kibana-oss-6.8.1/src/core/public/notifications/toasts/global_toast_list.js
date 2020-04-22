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
import { EuiGlobalToastList } from '@elastic/eui';
import React from 'react';
var GlobalToastList = /** @class */ (function (_super) {
    tslib_1.__extends(GlobalToastList, _super);
    function GlobalToastList() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.state = {
            toasts: [],
        };
        return _this;
    }
    GlobalToastList.prototype.componentDidMount = function () {
        var _this = this;
        this.subscription = this.props.toasts$.subscribe(function (toasts) {
            _this.setState({ toasts: toasts });
        });
    };
    GlobalToastList.prototype.componentWillUnmount = function () {
        if (this.subscription) {
            this.subscription.unsubscribe();
        }
    };
    GlobalToastList.prototype.render = function () {
        return (React.createElement(EuiGlobalToastList, { toasts: this.state.toasts, dismissToast: this.props.dismissToast, toastLifeTimeMs: 6000 }));
    };
    return GlobalToastList;
}(React.Component));
export { GlobalToastList };

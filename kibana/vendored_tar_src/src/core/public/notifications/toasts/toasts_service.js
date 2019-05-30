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
import React from 'react';
import { render, unmountComponentAtNode } from 'react-dom';
import { GlobalToastList } from './global_toast_list';
import { ToastsStartContract } from './toasts_start_contract';
var ToastsService = /** @class */ (function () {
    function ToastsService(params) {
        this.params = params;
    }
    ToastsService.prototype.start = function (_a) {
        var i18n = _a.i18n;
        var toasts = new ToastsStartContract();
        render(React.createElement(i18n.Context, null,
            React.createElement(GlobalToastList, { dismissToast: function (toast) { return toasts.remove(toast); }, "toasts$": toasts.get$() })), this.params.targetDomElement);
        return toasts;
    };
    ToastsService.prototype.stop = function () {
        unmountComponentAtNode(this.params.targetDomElement);
        this.params.targetDomElement.textContent = '';
    };
    return ToastsService;
}());
export { ToastsService };

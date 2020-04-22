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
var ToastNotifications = /** @class */ (function () {
    function ToastNotifications(toasts) {
        var _this = this;
        this.toasts = toasts;
        this.list = [];
        this.onChange = function (callback) {
            _this.onChangeCallback = callback;
        };
        this.add = function (toastOrTitle) { return _this.toasts.add(toastOrTitle); };
        this.remove = function (toast) { return _this.toasts.remove(toast); };
        this.addSuccess = function (toastOrTitle) { return _this.toasts.addSuccess(toastOrTitle); };
        this.addWarning = function (toastOrTitle) { return _this.toasts.addWarning(toastOrTitle); };
        this.addDanger = function (toastOrTitle) { return _this.toasts.addDanger(toastOrTitle); };
        toasts.get$().subscribe(function (list) {
            _this.list = list;
            if (_this.onChangeCallback) {
                _this.onChangeCallback();
            }
        });
    }
    return ToastNotifications;
}());
export { ToastNotifications };

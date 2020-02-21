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
import * as Rx from 'rxjs';
var normalizeToast = function (toastOrTitle) {
    if (typeof toastOrTitle === 'string') {
        return {
            title: toastOrTitle,
        };
    }
    return toastOrTitle;
};
var ToastsStartContract = /** @class */ (function () {
    function ToastsStartContract() {
        this.toasts$ = new Rx.BehaviorSubject([]);
        this.idCounter = 0;
    }
    ToastsStartContract.prototype.get$ = function () {
        return this.toasts$.asObservable();
    };
    ToastsStartContract.prototype.add = function (toastOrTitle) {
        var toast = tslib_1.__assign({ id: String(this.idCounter++) }, normalizeToast(toastOrTitle));
        this.toasts$.next(tslib_1.__spread(this.toasts$.getValue(), [toast]));
        return toast;
    };
    ToastsStartContract.prototype.remove = function (toast) {
        var list = this.toasts$.getValue();
        var listWithoutToast = list.filter(function (t) { return t !== toast; });
        if (listWithoutToast.length !== list.length) {
            this.toasts$.next(listWithoutToast);
        }
    };
    ToastsStartContract.prototype.addSuccess = function (toastOrTitle) {
        return this.add(tslib_1.__assign({ color: 'success', iconType: 'check' }, normalizeToast(toastOrTitle)));
    };
    ToastsStartContract.prototype.addWarning = function (toastOrTitle) {
        return this.add(tslib_1.__assign({ color: 'warning', iconType: 'help' }, normalizeToast(toastOrTitle)));
    };
    ToastsStartContract.prototype.addDanger = function (toastOrTitle) {
        return this.add(tslib_1.__assign({ color: 'danger', iconType: 'alert' }, normalizeToast(toastOrTitle)));
    };
    return ToastsStartContract;
}());
export { ToastsStartContract };

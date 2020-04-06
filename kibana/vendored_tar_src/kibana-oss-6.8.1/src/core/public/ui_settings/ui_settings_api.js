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
import { BehaviorSubject } from 'rxjs';
var NOOP_CHANGES = {
    values: {},
    callback: function () {
        // noop
    },
};
var UiSettingsApi = /** @class */ (function () {
    function UiSettingsApi(basePath, kibanaVersion) {
        this.basePath = basePath;
        this.kibanaVersion = kibanaVersion;
        this.sendInProgress = false;
        this.loadingCount$ = new BehaviorSubject(0);
    }
    /**
     * Adds a key+value that will be sent to the server ASAP. If a request is
     * already in progress it will wait until the previous request is complete
     * before sending the next request
     */
    UiSettingsApi.prototype.batchSet = function (key, value) {
        var _this = this;
        return new Promise(function (resolve, reject) {
            var _a;
            var prev = _this.pendingChanges || NOOP_CHANGES;
            _this.pendingChanges = {
                values: tslib_1.__assign({}, prev.values, (_a = {}, _a[key] = value, _a)),
                callback: function (error, resp) {
                    prev.callback(error, resp);
                    if (error) {
                        reject(error);
                    }
                    else {
                        resolve(resp);
                    }
                },
            };
            _this.flushPendingChanges();
        });
    };
    /**
     * Gets an observable that notifies subscribers of the current number of active requests
     */
    UiSettingsApi.prototype.getLoadingCount$ = function () {
        return this.loadingCount$.asObservable();
    };
    /**
     * Prepares the uiSettings API to be discarded
     */
    UiSettingsApi.prototype.stop = function () {
        this.loadingCount$.complete();
    };
    /**
     * If there are changes that need to be sent to the server and there is not already a
     * request in progress, this method will start a request sending those changes. Once
     * the request is complete `flushPendingChanges()` will be called again, and if the
     * prerequisites are still true (because changes were queued while the request was in
     * progress) then another request will be started until all pending changes have been
     * sent to the server.
     */
    UiSettingsApi.prototype.flushPendingChanges = function () {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var changes, _a, _b, _c, error_1;
            return tslib_1.__generator(this, function (_d) {
                switch (_d.label) {
                    case 0:
                        if (!this.pendingChanges) {
                            return [2 /*return*/];
                        }
                        if (this.sendInProgress) {
                            return [2 /*return*/];
                        }
                        changes = this.pendingChanges;
                        this.pendingChanges = undefined;
                        _d.label = 1;
                    case 1:
                        _d.trys.push([1, 3, 4, 5]);
                        this.sendInProgress = true;
                        _b = (_a = changes).callback;
                        _c = [undefined];
                        return [4 /*yield*/, this.sendRequest('POST', '/api/kibana/settings', {
                                changes: changes.values,
                            })];
                    case 2:
                        _b.apply(_a, _c.concat([_d.sent()]));
                        return [3 /*break*/, 5];
                    case 3:
                        error_1 = _d.sent();
                        changes.callback(error_1);
                        return [3 /*break*/, 5];
                    case 4:
                        this.sendInProgress = false;
                        this.flushPendingChanges();
                        return [7 /*endfinally*/];
                    case 5: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Calls window.fetch() with the proper headers and error handling logic.
     *
     * TODO: migrate this to kfetch or whatever the new platform equivalent is once it exists
     */
    UiSettingsApi.prototype.sendRequest = function (method, path, body) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var response;
            return tslib_1.__generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, , 3, 4]);
                        this.loadingCount$.next(this.loadingCount$.getValue() + 1);
                        return [4 /*yield*/, fetch(this.basePath.addToPath(path), {
                                method: method,
                                body: JSON.stringify(body),
                                headers: {
                                    accept: 'application/json',
                                    'content-type': 'application/json',
                                    'kbn-version': this.kibanaVersion,
                                },
                                credentials: 'same-origin',
                            })];
                    case 1:
                        response = _a.sent();
                        if (response.status >= 300) {
                            throw new Error("Request failed with status code: " + response.status);
                        }
                        return [4 /*yield*/, response.json()];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        this.loadingCount$.next(this.loadingCount$.getValue() - 1);
                        return [7 /*endfinally*/];
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    return UiSettingsApi;
}());
export { UiSettingsApi };

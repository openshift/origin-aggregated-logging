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
import { cloneDeep, defaultsDeep } from 'lodash';
import * as Rx from 'rxjs';
import { filter, map } from 'rxjs/operators';
var UiSettingsClient = /** @class */ (function () {
    function UiSettingsClient(params) {
        this.params = params;
        this.update$ = new Rx.Subject();
        this.api = params.api;
        this.onUpdateError = params.onUpdateError;
        this.defaults = cloneDeep(params.defaults);
        this.cache = defaultsDeep({}, this.defaults, cloneDeep(params.initialSettings));
    }
    /**
     * Gets the metadata about all uiSettings, including the type, default value, and user value
     * for each key.
     */
    UiSettingsClient.prototype.getAll = function () {
        return cloneDeep(this.cache);
    };
    /**
     * Gets the value for a specific uiSetting. If this setting has no user-defined value
     * then the `defaultOverride` parameter is returned (and parsed if setting is of type
     * "json" or "number). If the parameter is not defined and the key is not defined by a
     * uiSettingDefaults then an error is thrown, otherwise the default is read
     * from the uiSettingDefaults.
     */
    UiSettingsClient.prototype.get = function (key, defaultOverride) {
        var declared = this.isDeclared(key);
        if (!declared && defaultOverride !== undefined) {
            return defaultOverride;
        }
        if (!declared) {
            throw new Error("Unexpected `config.get(\"" + key + "\")` call on unrecognized configuration setting \"" + key + "\".\nSetting an initial value via `config.set(\"" + key + "\", value)` before attempting to retrieve\nany custom setting value for \"" + key + "\" may fix this issue.\nYou can use `config.get(\"" + key + "\", defaultValue)`, which will just return\n`defaultValue` when the key is unrecognized.");
        }
        var type = this.cache[key].type;
        var userValue = this.cache[key].userValue;
        var defaultValue = defaultOverride !== undefined ? defaultOverride : this.cache[key].value;
        var value = userValue == null ? defaultValue : userValue;
        if (type === 'json') {
            return JSON.parse(value);
        }
        if (type === 'number') {
            return parseFloat(value);
        }
        return value;
    };
    /**
     * Gets an observable of the current value for a config key, and all updates to that config
     * key in the future. Providing a `defaultOverride` argument behaves the same as it does in #get()
     */
    UiSettingsClient.prototype.get$ = function (key, defaultOverride) {
        var _this = this;
        return Rx.concat(Rx.defer(function () { return Rx.of(_this.get(key, defaultOverride)); }), this.update$.pipe(filter(function (update) { return update.key === key; }), map(function () { return _this.get(key, defaultOverride); })));
    };
    /**
     * Sets the value for a uiSetting. If the setting is not defined in the uiSettingDefaults
     * it will be stored as a custom setting. The new value will be synchronously available via
     * the `get()` method and sent to the server in the background. If the request to the
     * server fails then a toast notification will be displayed and the setting will be
     * reverted it its value before `set()` was called.
     */
    UiSettingsClient.prototype.set = function (key, val) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            return tslib_1.__generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, this.update(key, val)];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * Removes the user-defined value for a setting, causing it to revert to the default. This
     * method behaves the same as calling `set(key, null)`, including the synchronization, custom
     * setting, and error behavior of that method.
     */
    UiSettingsClient.prototype.remove = function (key) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            return tslib_1.__generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, this.update(key, null)];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * Returns true if the key is a "known" uiSetting, meaning it is either defined in the
     * uiSettingDefaults or was previously added as a custom setting via the `set()` method.
     */
    UiSettingsClient.prototype.isDeclared = function (key) {
        return key in this.cache;
    };
    /**
     * Returns true if the setting has no user-defined value or is unknown
     */
    UiSettingsClient.prototype.isDefault = function (key) {
        return !this.isDeclared(key) || this.cache[key].userValue == null;
    };
    /**
     * Returns true if the setting is not a part of the uiSettingDefaults, but was either
     * added directly via `set()`, or is an unknown setting found in the uiSettings saved
     * object
     */
    UiSettingsClient.prototype.isCustom = function (key) {
        return this.isDeclared(key) && !('value' in this.cache[key]);
    };
    /**
     * Returns true if a settings value is overridden by the server. When a setting is overridden
     * its value can not be changed via `set()` or `remove()`.
     */
    UiSettingsClient.prototype.isOverridden = function (key) {
        return this.isDeclared(key) && Boolean(this.cache[key].isOverridden);
    };
    /**
     * Overrides the default value for a setting in this specific browser tab. If the page
     * is reloaded the default override is lost.
     */
    UiSettingsClient.prototype.overrideLocalDefault = function (key, newDefault) {
        // capture the previous value
        var prevDefault = this.defaults[key] ? this.defaults[key].value : undefined;
        // update defaults map
        this.defaults[key] = tslib_1.__assign({}, (this.defaults[key] || {}), { value: newDefault });
        // update cached default value
        this.cache[key] = tslib_1.__assign({}, (this.cache[key] || {}), { value: newDefault });
        // don't broadcast change if userValue was already overriding the default
        if (this.cache[key].userValue == null) {
            this.update$.next({
                key: key,
                newValue: newDefault,
                oldValue: prevDefault,
            });
        }
    };
    /**
     * Returns an Observable that notifies subscribers of each update to the uiSettings,
     * including the key, newValue, and oldValue of the setting that changed.
     */
    UiSettingsClient.prototype.getUpdate$ = function () {
        return this.update$.asObservable();
    };
    /**
     * Prepares the uiSettingsClient to be discarded, completing any update$ observables
     * that have been created.
     */
    UiSettingsClient.prototype.stop = function () {
        this.update$.complete();
    };
    UiSettingsClient.prototype.assertUpdateAllowed = function (key) {
        if (this.isOverridden(key)) {
            throw new Error("Unable to update \"" + key + "\" because its value is overridden by the Kibana server");
        }
    };
    UiSettingsClient.prototype.update = function (key, newVal) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var declared, defaults, oldVal, unchanged, initialVal, settings, error_1;
            return tslib_1.__generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        this.assertUpdateAllowed(key);
                        declared = this.isDeclared(key);
                        defaults = this.defaults;
                        oldVal = declared ? this.cache[key].userValue : undefined;
                        unchanged = oldVal === newVal;
                        if (unchanged) {
                            return [2 /*return*/, true];
                        }
                        initialVal = declared ? this.get(key) : undefined;
                        this.setLocally(key, newVal);
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.api.batchSet(key, newVal)];
                    case 2:
                        settings = (_a.sent()).settings;
                        this.cache = defaultsDeep({}, defaults, settings);
                        return [2 /*return*/, true];
                    case 3:
                        error_1 = _a.sent();
                        this.setLocally(key, initialVal);
                        this.onUpdateError(error_1);
                        return [2 /*return*/, false];
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    UiSettingsClient.prototype.setLocally = function (key, newValue) {
        this.assertUpdateAllowed(key);
        if (!this.isDeclared(key)) {
            this.cache[key] = {};
        }
        var oldValue = this.get(key);
        if (newValue === null) {
            delete this.cache[key].userValue;
        }
        else {
            var type = this.cache[key].type;
            if (type === 'json' && typeof newValue !== 'string') {
                this.cache[key].userValue = JSON.stringify(newValue);
            }
            else {
                this.cache[key].userValue = newValue;
            }
        }
        this.update$.next({ key: key, newValue: newValue, oldValue: oldValue });
    };
    return UiSettingsClient;
}());
export { UiSettingsClient };

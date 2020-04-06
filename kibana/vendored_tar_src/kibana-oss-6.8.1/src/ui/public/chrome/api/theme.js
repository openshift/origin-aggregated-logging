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
var newPlatformChrome;
export function __newPlatformInit__(instance) {
    if (newPlatformChrome) {
        throw new Error('ui/chrome/api/theme is already initialized');
    }
    newPlatformChrome = instance;
}
export function initChromeThemeApi(chrome) {
    var brandCache$ = new Rx.BehaviorSubject({});
    newPlatformChrome.getBrand$().subscribe(brandCache$);
    var applicationClassesCache$ = new Rx.BehaviorSubject([]);
    newPlatformChrome.getApplicationClasses$().subscribe(applicationClassesCache$);
    chrome.setBrand = function (brand) {
        newPlatformChrome.setBrand(brand);
        return chrome;
    };
    chrome.getBrand = function (key) {
        return brandCache$.getValue()[key];
    };
    chrome.addApplicationClass = function (classNames) {
        if (classNames === void 0) { classNames = []; }
        var e_1, _a;
        if (typeof classNames === 'string') {
            classNames = [classNames];
        }
        try {
            for (var classNames_1 = tslib_1.__values(classNames), classNames_1_1 = classNames_1.next(); !classNames_1_1.done; classNames_1_1 = classNames_1.next()) {
                var className = classNames_1_1.value;
                newPlatformChrome.addApplicationClass(className);
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (classNames_1_1 && !classNames_1_1.done && (_a = classNames_1.return)) _a.call(classNames_1);
            }
            finally { if (e_1) throw e_1.error; }
        }
        return chrome;
    };
    chrome.removeApplicationClass = function (classNames) {
        var e_2, _a;
        if (typeof classNames === 'string') {
            classNames = [classNames];
        }
        try {
            for (var classNames_2 = tslib_1.__values(classNames), classNames_2_1 = classNames_2.next(); !classNames_2_1.done; classNames_2_1 = classNames_2.next()) {
                var className = classNames_2_1.value;
                newPlatformChrome.removeApplicationClass(className);
            }
        }
        catch (e_2_1) { e_2 = { error: e_2_1 }; }
        finally {
            try {
                if (classNames_2_1 && !classNames_2_1.done && (_a = classNames_2.return)) _a.call(classNames_2);
            }
            finally { if (e_2) throw e_2.error; }
        }
        return chrome;
    };
    chrome.getApplicationClasses = function () {
        return applicationClassesCache$.getValue().join(' ');
    };
}

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
import { merge } from 'lodash';
// @ts-ignore not really worth typing
import { metadata } from 'ui/metadata';
import url from 'url';
import chrome from '../chrome';
import { KFetchError } from './kfetch_error';
var interceptors = [];
export var resetInterceptors = function () { return (interceptors.length = 0); };
export var addInterceptor = function (interceptor) { return interceptors.push(interceptor); };
export function kfetch(options, _a) {
    var _b = (_a === void 0 ? {} : _a).prependBasePath, prependBasePath = _b === void 0 ? true : _b;
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var combinedOptions, promise;
        var _this = this;
        return tslib_1.__generator(this, function (_c) {
            combinedOptions = withDefaultOptions(options);
            promise = requestInterceptors(combinedOptions).then(function (_a) {
                var pathname = _a.pathname, query = _a.query, restOptions = tslib_1.__rest(_a, ["pathname", "query"]);
                var fullUrl = url.format({
                    pathname: prependBasePath ? chrome.addBasePath(pathname) : pathname,
                    query: query,
                });
                return window.fetch(fullUrl, restOptions).then(function (res) { return tslib_1.__awaiter(_this, void 0, void 0, function () {
                    var body;
                    return tslib_1.__generator(this, function (_a) {
                        switch (_a.label) {
                            case 0: return [4 /*yield*/, getBodyAsJson(res)];
                            case 1:
                                body = _a.sent();
                                if (res.ok) {
                                    return [2 /*return*/, body];
                                }
                                throw new KFetchError(res, body);
                        }
                    });
                }); });
            });
            return [2 /*return*/, responseInterceptors(promise)];
        });
    });
}
// Request/response interceptors are called in opposite orders.
// Request hooks start from the newest interceptor and end with the oldest.
function requestInterceptors(config) {
    return interceptors.reduceRight(function (acc, interceptor) {
        return acc.then(interceptor.request, interceptor.requestError);
    }, Promise.resolve(config));
}
// Response hooks start from the oldest interceptor and end with the newest.
function responseInterceptors(responsePromise) {
    return interceptors.reduce(function (acc, interceptor) {
        return acc.then(interceptor.response, interceptor.responseError);
    }, responsePromise);
}
function getBodyAsJson(res) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var e_1;
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _a.trys.push([0, 2, , 3]);
                    return [4 /*yield*/, res.json()];
                case 1: return [2 /*return*/, _a.sent()];
                case 2:
                    e_1 = _a.sent();
                    return [2 /*return*/, null];
                case 3: return [2 /*return*/];
            }
        });
    });
}
export function withDefaultOptions(options) {
    return merge({
        method: 'GET',
        credentials: 'same-origin',
        headers: {
            'Content-Type': 'application/json',
            'kbn-version': metadata.version,
        },
    }, options);
}

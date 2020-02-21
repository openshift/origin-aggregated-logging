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
import { kfetch } from 'ui/kfetch';
import url from 'url';
import chrome from '../../chrome';
export function shortenUrl(absoluteUrl) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var basePath, parsedUrl, path, hash, relativeUrl, body, resp;
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    basePath = chrome.getBasePath();
                    parsedUrl = url.parse(absoluteUrl);
                    if (!parsedUrl || !parsedUrl.path) {
                        return [2 /*return*/];
                    }
                    path = parsedUrl.path.replace(basePath, '');
                    hash = parsedUrl.hash ? parsedUrl.hash : '';
                    relativeUrl = path + hash;
                    body = JSON.stringify({ url: relativeUrl });
                    return [4 /*yield*/, kfetch({ method: 'POST', pathname: '/api/shorten_url', body: body })];
                case 1:
                    resp = _a.sent();
                    return [2 /*return*/, url.format({
                            protocol: parsedUrl.protocol,
                            host: parsedUrl.host,
                            pathname: basePath + "/goto/" + resp.urlId,
                        })];
            }
        });
    });
}

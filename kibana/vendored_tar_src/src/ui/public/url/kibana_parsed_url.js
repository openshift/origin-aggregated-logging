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
import { parse } from 'url';
import { modifyUrl } from '../../../core/public/utils';
import { prependPath } from './prepend_path';
/**
 * Represents the pieces that make up a url in Kibana, offering some helpful functionality
 * for translating those pieces into absolute or relative urls. A Kibana url with a basePath
 * looks like this: http://localhost:5601/basePath/app/appId#/an/appPath?with=query&params
 *
 *  - basePath is "/basePath"
 *  - appId is "appId"
 *  - appPath is "/an/appPath?with=query&params"
 *
 * Almost all urls in Kibana should have this structure, including the "/app" portion in front of the appId
 * (one exception is the login link).
 */
var KibanaParsedUrl = /** @class */ (function () {
    function KibanaParsedUrl(options) {
        var appId = options.appId, _a = options.basePath, basePath = _a === void 0 ? '' : _a, _b = options.appPath, appPath = _b === void 0 ? '' : _b, hostname = options.hostname, protocol = options.protocol, port = options.port;
        // We'll use window defaults
        var hostOrProtocolSpecified = hostname || protocol || port;
        this.basePath = basePath;
        this.appId = appId;
        this.appPath = appPath;
        this.hostname = hostOrProtocolSpecified ? hostname : window.location.hostname;
        this.port = hostOrProtocolSpecified ? port : window.location.port;
        this.protocol = hostOrProtocolSpecified ? protocol : window.location.protocol;
    }
    KibanaParsedUrl.prototype.getGlobalState = function () {
        if (!this.appPath) {
            return '';
        }
        var parsedUrl = parse(this.appPath, true);
        var query = parsedUrl.query || {};
        return query._g || '';
    };
    KibanaParsedUrl.prototype.setGlobalState = function (newGlobalState) {
        if (!this.appPath) {
            return;
        }
        this.appPath = modifyUrl(this.appPath, function (parsed) {
            parsed.query._g = newGlobalState;
        });
    };
    KibanaParsedUrl.prototype.addQueryParameter = function (name, val) {
        this.appPath = modifyUrl(this.appPath, function (parsed) {
            parsed.query[name] = val;
        });
    };
    KibanaParsedUrl.prototype.getHashedAppPath = function () {
        return "#" + this.appPath;
    };
    KibanaParsedUrl.prototype.getAppBasePath = function () {
        return "/" + this.appId;
    };
    KibanaParsedUrl.prototype.getAppRootPath = function () {
        return "/app" + this.getAppBasePath() + this.getHashedAppPath();
    };
    KibanaParsedUrl.prototype.getRootRelativePath = function () {
        return prependPath(this.getAppRootPath(), this.basePath);
    };
    KibanaParsedUrl.prototype.getAbsoluteUrl = function () {
        var _this = this;
        return modifyUrl(this.getRootRelativePath(), function (parsed) {
            parsed.protocol = _this.protocol;
            parsed.port = _this.port;
            parsed.hostname = _this.hostname;
        });
    };
    return KibanaParsedUrl;
}());
export { KibanaParsedUrl };

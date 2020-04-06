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
import { get } from 'lodash';
import { deepFreeze } from './deep_freeze';
/**
 * Provides access to the metadata that is injected by the
 * server into the page. The metadata is actually defined
 * in the entry file for the bundle containing the new platform
 * and is read from the DOM in most cases.
 */
var InjectedMetadataService = /** @class */ (function () {
    function InjectedMetadataService(params) {
        this.params = params;
        this.state = deepFreeze(this.params.injectedMetadata);
    }
    InjectedMetadataService.prototype.start = function () {
        var _this = this;
        return {
            getBasePath: function () {
                return _this.state.basePath;
            },
            getKibanaVersion: function () {
                return _this.getKibanaVersion();
            },
            getLegacyMetadata: function () {
                return _this.state.legacyMetadata;
            },
            getInjectedVar: function (name, defaultValue) {
                return get(_this.state.vars, name, defaultValue);
            },
            getInjectedVars: function () {
                return _this.state.vars;
            },
        };
    };
    InjectedMetadataService.prototype.getKibanaVersion = function () {
        return this.state.version;
    };
    InjectedMetadataService.prototype.getKibanaBuildNumber = function () {
        return this.state.buildNumber;
    };
    return InjectedMetadataService;
}());
export { InjectedMetadataService };

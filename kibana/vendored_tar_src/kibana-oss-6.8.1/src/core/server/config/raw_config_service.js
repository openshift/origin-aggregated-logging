"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const lodash_1 = require("lodash");
const rxjs_1 = require("rxjs");
const operators_1 = require("rxjs/operators");
const type_detect_1 = tslib_1.__importDefault(require("type-detect"));
const object_to_config_adapter_1 = require("./object_to_config_adapter");
const read_config_1 = require("./read_config");
/** @internal */
class RawConfigService {
    constructor(configFiles, configAdapter = rawConfig => new object_to_config_adapter_1.ObjectToConfigAdapter(rawConfig)) {
        this.configFiles = configFiles;
        /**
         * The stream of configs read from the config file.
         *
         * This is the _raw_ config before any overrides are applied.
         */
        this.rawConfigFromFile$ = new rxjs_1.ReplaySubject(1);
        this.config$ = this.rawConfigFromFile$.pipe(operators_1.map(rawConfig => {
            if (lodash_1.isPlainObject(rawConfig)) {
                // TODO Make config consistent, e.g. handle dots in keys
                return configAdapter(lodash_1.cloneDeep(rawConfig));
            }
            throw new Error(`the raw config must be an object, got [${type_detect_1.default(rawConfig)}]`);
        }));
    }
    /**
     * Read the initial Kibana config.
     */
    loadConfig() {
        this.rawConfigFromFile$.next(read_config_1.getConfigFromFiles(this.configFiles));
    }
    stop() {
        this.rawConfigFromFile$.complete();
    }
    /**
     * Re-read the Kibana config.
     */
    reloadConfig() {
        this.loadConfig();
    }
    getConfig$() {
        return this.config$;
    }
}
exports.RawConfigService = RawConfigService;

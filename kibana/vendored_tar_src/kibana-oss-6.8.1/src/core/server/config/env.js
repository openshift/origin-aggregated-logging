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
const path_1 = require("path");
const process_1 = tslib_1.__importDefault(require("process"));
const package_json_1 = require("../../../utils/package_json");
class Env {
    /**
     * @internal
     */
    constructor(homeDir, options) {
        this.homeDir = homeDir;
        this.configDir = path_1.resolve(this.homeDir, 'config');
        this.binDir = path_1.resolve(this.homeDir, 'bin');
        this.logDir = path_1.resolve(this.homeDir, 'log');
        this.staticFilesDir = path_1.resolve(this.homeDir, 'ui');
        this.pluginSearchPaths = [
            path_1.resolve(this.homeDir, 'src', 'plugins'),
            path_1.resolve(this.homeDir, 'plugins'),
            path_1.resolve(this.homeDir, '..', 'kibana-extra'),
        ];
        this.cliArgs = Object.freeze(options.cliArgs);
        this.configs = Object.freeze(options.configs);
        this.isDevClusterMaster = options.isDevClusterMaster;
        const isDevMode = this.cliArgs.dev || this.cliArgs.envName === 'development';
        this.mode = Object.freeze({
            dev: isDevMode,
            name: isDevMode ? 'development' : 'production',
            prod: !isDevMode,
        });
        const isKibanaDistributable = package_json_1.pkg.build && package_json_1.pkg.build.distributable === true;
        this.packageInfo = Object.freeze({
            branch: package_json_1.pkg.branch,
            buildNum: isKibanaDistributable ? package_json_1.pkg.build.number : Number.MAX_SAFE_INTEGER,
            buildSha: isKibanaDistributable ? package_json_1.pkg.build.sha : 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
            version: package_json_1.pkg.version,
        });
    }
    /**
     * @internal
     */
    static createDefault(options) {
        return new Env(process_1.default.cwd(), options);
    }
}
exports.Env = Env;

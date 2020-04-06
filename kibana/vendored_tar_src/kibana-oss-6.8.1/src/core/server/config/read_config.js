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
const fs_1 = require("fs");
const js_yaml_1 = require("js-yaml");
const lodash_1 = require("lodash");
const ensure_deep_object_1 = require("./ensure_deep_object");
const readYaml = (path) => js_yaml_1.safeLoad(fs_1.readFileSync(path, 'utf8'));
function replaceEnvVarRefs(val) {
    return val.replace(/\$\{(\w+)\}/g, (match, envVarName) => {
        const envVarValue = process.env[envVarName];
        if (envVarValue !== undefined) {
            return envVarValue;
        }
        throw new Error(`Unknown environment variable referenced in config : ${envVarName}`);
    });
}
function merge(target, value, key) {
    if ((lodash_1.isPlainObject(value) || Array.isArray(value)) && Object.keys(value).length > 0) {
        for (const [subKey, subVal] of Object.entries(value)) {
            merge(target, subVal, key ? `${key}.${subKey}` : subKey);
        }
    }
    else if (key !== undefined) {
        lodash_1.set(target, key, typeof value === 'string' ? replaceEnvVarRefs(value) : value);
    }
    return target;
}
/** @internal */
exports.getConfigFromFiles = (configFiles) => {
    let mergedYaml = {};
    for (const configFile of configFiles) {
        const yaml = readYaml(configFile);
        if (yaml !== null) {
            mergedYaml = merge(mergedYaml, yaml);
        }
    }
    return ensure_deep_object_1.ensureDeepObject(mergedYaml);
};

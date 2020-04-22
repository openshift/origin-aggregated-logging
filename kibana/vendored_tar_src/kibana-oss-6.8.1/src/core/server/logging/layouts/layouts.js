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
const config_schema_1 = require("@kbn/config-schema");
const utils_1 = require("../../../utils");
const json_layout_1 = require("./json_layout");
const pattern_layout_1 = require("./pattern_layout");
const { oneOf } = config_schema_1.schema;
/** @internal */
class Layouts {
    /**
     * Factory method that creates specific `Layout` instances based on the passed `config` parameter.
     * @param config Configuration specific to a particular `Layout` implementation.
     * @returns Fully constructed `Layout` instance.
     */
    static create(config) {
        switch (config.kind) {
            case 'json':
                return new json_layout_1.JsonLayout();
            case 'pattern':
                return new pattern_layout_1.PatternLayout(config.pattern, config.highlight);
            default:
                return utils_1.assertNever(config);
        }
    }
}
Layouts.configSchema = oneOf([json_layout_1.JsonLayout.configSchema, pattern_layout_1.PatternLayout.configSchema]);
exports.Layouts = Layouts;

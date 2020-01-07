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
const legacy_appender_1 = require("../../legacy_compat/logging/appenders/legacy_appender");
const layouts_1 = require("../layouts/layouts");
const console_appender_1 = require("./console/console_appender");
const file_appender_1 = require("./file/file_appender");
const appendersSchema = config_schema_1.schema.oneOf([
    console_appender_1.ConsoleAppender.configSchema,
    file_appender_1.FileAppender.configSchema,
    legacy_appender_1.LegacyAppender.configSchema,
]);
/** @internal */
class Appenders {
    /**
     * Factory method that creates specific `Appender` instances based on the passed `config` parameter.
     * @param config Configuration specific to a particular `Appender` implementation.
     * @returns Fully constructed `Appender` instance.
     */
    static create(config) {
        switch (config.kind) {
            case 'console':
                return new console_appender_1.ConsoleAppender(layouts_1.Layouts.create(config.layout));
            case 'file':
                return new file_appender_1.FileAppender(layouts_1.Layouts.create(config.layout), config.path);
            case 'legacy-appender':
                return new legacy_appender_1.LegacyAppender(config.legacyLoggingConfig);
            default:
                return utils_1.assertNever(config);
        }
    }
}
Appenders.configSchema = appendersSchema;
exports.Appenders = Appenders;

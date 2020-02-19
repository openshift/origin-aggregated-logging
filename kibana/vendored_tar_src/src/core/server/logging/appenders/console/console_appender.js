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
const layouts_1 = require("../../layouts/layouts");
const { literal, object } = config_schema_1.schema;
/**
 * Appender that formats all the `LogRecord` instances it receives and logs them via built-in `console`.
 * @internal
 */
class ConsoleAppender {
    /**
     * Creates ConsoleAppender instance.
     * @param layout Instance of `Layout` sub-class responsible for `LogRecord` formatting.
     */
    constructor(layout) {
        this.layout = layout;
    }
    /**
     * Formats specified `record` and logs it via built-in `console`.
     * @param record `LogRecord` instance to be logged.
     */
    append(record) {
        // tslint:disable no-console
        console.log(this.layout.format(record));
    }
    /**
     * Disposes `ConsoleAppender`.
     */
    dispose() {
        // noop
    }
}
ConsoleAppender.configSchema = object({
    kind: literal('console'),
    layout: layouts_1.Layouts.configSchema,
});
exports.ConsoleAppender = ConsoleAppender;

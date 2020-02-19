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
const fs_1 = require("fs");
const layouts_1 = require("../../layouts/layouts");
/**
 * Appender that formats all the `LogRecord` instances it receives and writes them to the specified file.
 * @internal
 */
class FileAppender {
    /**
     * Creates FileAppender instance with specified layout and file path.
     * @param layout Instance of `Layout` sub-class responsible for `LogRecord` formatting.
     * @param path Path to the file where log records should be stored.
     */
    constructor(layout, path) {
        this.layout = layout;
        this.path = path;
    }
    /**
     * Formats specified `record` and writes them to the specified file.
     * @param record `LogRecord` instance to be logged.
     */
    append(record) {
        if (this.outputStream === undefined) {
            this.outputStream = fs_1.createWriteStream(this.path, {
                encoding: 'utf8',
                flags: 'a',
            });
        }
        this.outputStream.write(`${this.layout.format(record)}\n`);
    }
    /**
     * Disposes `FileAppender`. Waits for the underlying file stream to be completely flushed and closed.
     */
    async dispose() {
        await new Promise(resolve => {
            if (this.outputStream === undefined) {
                return resolve();
            }
            this.outputStream.end(undefined, undefined, () => {
                this.outputStream = undefined;
                resolve();
            });
        });
    }
}
FileAppender.configSchema = config_schema_1.schema.object({
    kind: config_schema_1.schema.literal('file'),
    layout: layouts_1.Layouts.configSchema,
    path: config_schema_1.schema.string(),
});
exports.FileAppender = FileAppender;

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
const legacy_logging_server_1 = require("../legacy_logging_server");
/**
 * Simple appender that just forwards `LogRecord` to the legacy KbnServer log.
 * @internal
 */
class LegacyAppender {
    constructor(legacyLoggingConfig) {
        this.loggingServer = new legacy_logging_server_1.LegacyLoggingServer(legacyLoggingConfig);
    }
    /**
     * Forwards `LogRecord` to the legacy platform that will layout and
     * write record to the configured destination.
     * @param record `LogRecord` instance to forward to.
     */
    append(record) {
        this.loggingServer.log(record);
    }
    dispose() {
        this.loggingServer.stop();
    }
}
LegacyAppender.configSchema = config_schema_1.schema.object({
    kind: config_schema_1.schema.literal('legacy-appender'),
    legacyLoggingConfig: config_schema_1.schema.any(),
});
exports.LegacyAppender = LegacyAppender;

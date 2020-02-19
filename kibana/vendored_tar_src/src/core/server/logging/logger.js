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
const log_level_1 = require("./log_level");
function isError(x) {
    return x instanceof Error;
}
/** @internal */
class BaseLogger {
    constructor(context, level, appenders) {
        this.context = context;
        this.level = level;
        this.appenders = appenders;
    }
    trace(message, meta) {
        this.log(this.createLogRecord(log_level_1.LogLevel.Trace, message, meta));
    }
    debug(message, meta) {
        this.log(this.createLogRecord(log_level_1.LogLevel.Debug, message, meta));
    }
    info(message, meta) {
        this.log(this.createLogRecord(log_level_1.LogLevel.Info, message, meta));
    }
    warn(errorOrMessage, meta) {
        this.log(this.createLogRecord(log_level_1.LogLevel.Warn, errorOrMessage, meta));
    }
    error(errorOrMessage, meta) {
        this.log(this.createLogRecord(log_level_1.LogLevel.Error, errorOrMessage, meta));
    }
    fatal(errorOrMessage, meta) {
        this.log(this.createLogRecord(log_level_1.LogLevel.Fatal, errorOrMessage, meta));
    }
    log(record) {
        if (!this.level.supports(record.level)) {
            return;
        }
        for (const appender of this.appenders) {
            appender.append(record);
        }
    }
    createLogRecord(level, errorOrMessage, meta) {
        if (isError(errorOrMessage)) {
            return {
                context: this.context,
                error: errorOrMessage,
                level,
                message: errorOrMessage.message,
                meta,
                timestamp: new Date(),
            };
        }
        return {
            context: this.context,
            level,
            message: errorOrMessage,
            meta,
            timestamp: new Date(),
        };
    }
}
exports.BaseLogger = BaseLogger;

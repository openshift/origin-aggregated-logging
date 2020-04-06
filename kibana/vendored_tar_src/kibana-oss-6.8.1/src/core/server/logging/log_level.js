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
const utils_1 = require("../../utils");
/**
 * Represents the log level, manages string -> `LogLevel` conversion and comparison of log level
 * priorities between themselves.
 * @internal
 */
class LogLevel {
    constructor(id, value) {
        this.id = id;
        this.value = value;
    }
    /**
     * Converts string representation of log level into `LogLevel` instance.
     * @param level String representation of log level.
     * @returns Instance of `LogLevel` class.
     */
    static fromId(level) {
        switch (level) {
            case 'all':
                return LogLevel.All;
            case 'fatal':
                return LogLevel.Fatal;
            case 'error':
                return LogLevel.Error;
            case 'warn':
                return LogLevel.Warn;
            case 'info':
                return LogLevel.Info;
            case 'debug':
                return LogLevel.Debug;
            case 'trace':
                return LogLevel.Trace;
            case 'off':
                return LogLevel.Off;
            default:
                return utils_1.assertNever(level);
        }
    }
    /**
     * Indicates whether current log level covers the one that is passed as an argument.
     * @param level Instance of `LogLevel` to compare to.
     * @returns True if specified `level` is covered by this log level.
     */
    supports(level) {
        return this.value >= level.value;
    }
}
LogLevel.Off = new LogLevel('off', 1);
LogLevel.Fatal = new LogLevel('fatal', 2);
LogLevel.Error = new LogLevel('error', 3);
LogLevel.Warn = new LogLevel('warn', 4);
LogLevel.Info = new LogLevel('info', 5);
LogLevel.Debug = new LogLevel('debug', 6);
LogLevel.Trace = new LogLevel('trace', 7);
LogLevel.All = new LogLevel('all', 8);
exports.LogLevel = LogLevel;

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
const config_schema_1 = require("@kbn/config-schema");
const chalk_1 = tslib_1.__importDefault(require("chalk"));
const log_level_1 = require("../log_level");
/**
 * A set of static constants describing supported parameters in the log message pattern.
 */
const Parameters = Object.freeze({
    Context: '{context}',
    Level: '{level}',
    Message: '{message}',
    Timestamp: '{timestamp}',
});
/**
 * Regular expression used to parse log message pattern and fill in placeholders
 * with the actual data.
 */
const PATTERN_REGEX = new RegExp(`${Parameters.Timestamp}|${Parameters.Level}|${Parameters.Context}|${Parameters.Message}`, 'gi');
/**
 * Mapping between `LogLevel` and color that is used to highlight `level` part of
 * the log message.
 */
const LEVEL_COLORS = new Map([
    [log_level_1.LogLevel.Fatal, chalk_1.default.red],
    [log_level_1.LogLevel.Error, chalk_1.default.red],
    [log_level_1.LogLevel.Warn, chalk_1.default.yellow],
    [log_level_1.LogLevel.Debug, chalk_1.default.green],
    [log_level_1.LogLevel.Trace, chalk_1.default.blue],
]);
/**
 * Default pattern used by PatternLayout if it's not overridden in the configuration.
 */
const DEFAULT_PATTERN = `[${Parameters.Timestamp}][${Parameters.Level}][${Parameters.Context}] ${Parameters.Message}`;
const patternLayoutSchema = config_schema_1.schema.object({
    highlight: config_schema_1.schema.maybe(config_schema_1.schema.boolean()),
    kind: config_schema_1.schema.literal('pattern'),
    pattern: config_schema_1.schema.maybe(config_schema_1.schema.string()),
});
/**
 * Layout that formats `LogRecord` using the `pattern` string with optional
 * color highlighting (eg. to make log messages easier to read in the terminal).
 * @internal
 */
class PatternLayout {
    constructor(pattern = DEFAULT_PATTERN, highlight = false) {
        this.pattern = pattern;
        this.highlight = highlight;
    }
    static highlightRecord(record, formattedRecord) {
        if (LEVEL_COLORS.has(record.level)) {
            const color = LEVEL_COLORS.get(record.level);
            formattedRecord.set(Parameters.Level, color(formattedRecord.get(Parameters.Level)));
        }
        formattedRecord.set(Parameters.Context, chalk_1.default.magenta(formattedRecord.get(Parameters.Context)));
    }
    /**
     * Formats `LogRecord` into a string based on the specified `pattern` and `highlighting` options.
     * @param record Instance of `LogRecord` to format into string.
     */
    format(record) {
        // Error stack is much more useful than just the message.
        const message = (record.error && record.error.stack) || record.message;
        const formattedRecord = new Map([
            [Parameters.Timestamp, record.timestamp.toISOString()],
            [Parameters.Level, record.level.id.toUpperCase().padEnd(5)],
            [Parameters.Context, record.context],
            [Parameters.Message, message],
        ]);
        if (this.highlight) {
            PatternLayout.highlightRecord(record, formattedRecord);
        }
        return this.pattern.replace(PATTERN_REGEX, match => formattedRecord.get(match));
    }
}
PatternLayout.configSchema = patternLayoutSchema;
exports.PatternLayout = PatternLayout;

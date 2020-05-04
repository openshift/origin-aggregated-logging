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
const appenders_1 = require("./appenders/appenders");
// We need this helper for the types to be correct
// (otherwise it assumes an array of A|B instead of a tuple [A,B])
const toTuple = (a, b) => [a, b];
/**
 * Separator string that used within nested context name (eg. plugins.pid).
 */
const CONTEXT_SEPARATOR = '.';
/**
 * Name of the `root` context that always exists and sits at the top of logger hierarchy.
 */
const ROOT_CONTEXT_NAME = 'root';
/**
 * Name of the appender that is always presented and used by `root` logger by default.
 */
const DEFAULT_APPENDER_NAME = 'default';
const createLevelSchema = config_schema_1.schema.oneOf([
    config_schema_1.schema.literal('all'),
    config_schema_1.schema.literal('fatal'),
    config_schema_1.schema.literal('error'),
    config_schema_1.schema.literal('warn'),
    config_schema_1.schema.literal('info'),
    config_schema_1.schema.literal('debug'),
    config_schema_1.schema.literal('trace'),
    config_schema_1.schema.literal('off'),
], {
    defaultValue: 'info',
});
const createLoggerSchema = config_schema_1.schema.object({
    appenders: config_schema_1.schema.arrayOf(config_schema_1.schema.string(), { defaultValue: [] }),
    context: config_schema_1.schema.string(),
    level: createLevelSchema,
});
const loggingSchema = config_schema_1.schema.object({
    appenders: config_schema_1.schema.mapOf(config_schema_1.schema.string(), appenders_1.Appenders.configSchema, {
        defaultValue: new Map(),
    }),
    loggers: config_schema_1.schema.arrayOf(createLoggerSchema, {
        defaultValue: [],
    }),
    root: config_schema_1.schema.object({
        appenders: config_schema_1.schema.arrayOf(config_schema_1.schema.string(), {
            defaultValue: [DEFAULT_APPENDER_NAME],
            minSize: 1,
        }),
        level: createLevelSchema,
    }),
});
/**
 * Describes the config used to fully setup logging subsystem.
 * @internal
 */
class LoggingConfig {
    constructor(configType) {
        /**
         * Map of the appender unique arbitrary key and its corresponding config.
         */
        this.appenders = new Map([
            [
                DEFAULT_APPENDER_NAME,
                {
                    kind: 'console',
                    layout: { kind: 'pattern', highlight: true },
                },
            ],
        ]);
        /**
         * Map of the logger unique arbitrary key (context) and its corresponding config.
         */
        this.loggers = new Map();
        this.fillAppendersConfig(configType);
        this.fillLoggersConfig(configType);
    }
    /**
     * Helper method that joins separate string context parts into single context string.
     * In case joined context is an empty string, `root` context name is returned.
     * @param contextParts List of the context parts (e.g. ['parent', 'child'].
     * @returns {string} Joined context string (e.g. 'parent.child').
     */
    static getLoggerContext(contextParts) {
        return contextParts.join(CONTEXT_SEPARATOR) || ROOT_CONTEXT_NAME;
    }
    /**
     * Helper method that returns parent context for the specified one.
     * @param context Context to find parent for.
     * @returns Name of the parent context or `root` if the context is the top level one.
     */
    static getParentLoggerContext(context) {
        const lastIndexOfSeparator = context.lastIndexOf(CONTEXT_SEPARATOR);
        if (lastIndexOfSeparator === -1) {
            return ROOT_CONTEXT_NAME;
        }
        return context.slice(0, lastIndexOfSeparator);
    }
    fillAppendersConfig(loggingConfig) {
        for (const [appenderKey, appenderSchema] of loggingConfig.appenders) {
            this.appenders.set(appenderKey, appenderSchema);
        }
    }
    fillLoggersConfig(loggingConfig) {
        // Include `root` logger into common logger list so that it can easily be a part
        // of the logger hierarchy and put all the loggers in map for easier retrieval.
        const loggers = [
            { context: ROOT_CONTEXT_NAME, ...loggingConfig.root },
            ...loggingConfig.loggers,
        ];
        const loggerConfigByContext = new Map(loggers.map(loggerConfig => toTuple(loggerConfig.context, loggerConfig)));
        for (const [loggerContext, loggerConfig] of loggerConfigByContext) {
            // Ensure logger config only contains valid appenders.
            const unsupportedAppenderKey = loggerConfig.appenders.find(appenderKey => !this.appenders.has(appenderKey));
            if (unsupportedAppenderKey) {
                throw new Error(`Logger "${loggerContext}" contains unsupported appender key "${unsupportedAppenderKey}".`);
            }
            const appenders = getAppenders(loggerConfig, loggerConfigByContext);
            // We expect `appenders` to never be empty at this point, since the `root` context config should always
            // have at least one appender that is enforced by the config schema validation.
            this.loggers.set(loggerContext, {
                ...loggerConfig,
                appenders,
            });
        }
    }
}
LoggingConfig.schema = loggingSchema;
exports.LoggingConfig = LoggingConfig;
/**
 * Get appenders for logger config.
 *
 * If config for current context doesn't have any defined appenders inherit
 * appenders from the parent context config.
 */
function getAppenders(loggerConfig, loggerConfigByContext) {
    let currentContext = loggerConfig.context;
    let appenders = loggerConfig.appenders;
    while (appenders.length === 0) {
        const parentContext = LoggingConfig.getParentLoggerContext(currentContext);
        const parentLogger = loggerConfigByContext.get(parentContext);
        if (parentLogger) {
            appenders = parentLogger.appenders;
        }
        currentContext = parentContext;
    }
    return appenders;
}

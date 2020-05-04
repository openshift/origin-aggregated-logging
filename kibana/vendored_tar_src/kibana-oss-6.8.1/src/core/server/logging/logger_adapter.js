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
/** @internal */
class LoggerAdapter {
    constructor(logger) {
        this.logger = logger;
    }
    /**
     * The current logger can be updated "on the fly", e.g. when the log config
     * has changed.
     *
     * This is not intended for external use, only internally in Kibana
     *
     * @internal
     */
    updateLogger(logger) {
        this.logger = logger;
    }
    trace(message, meta) {
        this.logger.trace(message, meta);
    }
    debug(message, meta) {
        this.logger.debug(message, meta);
    }
    info(message, meta) {
        this.logger.info(message, meta);
    }
    warn(errorOrMessage, meta) {
        this.logger.warn(errorOrMessage, meta);
    }
    error(errorOrMessage, meta) {
        this.logger.error(errorOrMessage, meta);
    }
    fatal(errorOrMessage, meta) {
        this.logger.fatal(errorOrMessage, meta);
    }
    log(record) {
        this.logger.log(record);
    }
}
exports.LoggerAdapter = LoggerAdapter;

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class TaskManagerLogger {
    constructor(log) {
        this.write = log;
    }
    error(msg) {
        this.log('error', msg);
    }
    warning(msg) {
        this.log('warning', msg);
    }
    debug(msg) {
        this.log('debug', msg);
    }
    info(msg) {
        this.log('info', msg);
    }
    log(type, msg) {
        this.write([type, 'task_manager'], msg);
    }
}
exports.TaskManagerLogger = TaskManagerLogger;

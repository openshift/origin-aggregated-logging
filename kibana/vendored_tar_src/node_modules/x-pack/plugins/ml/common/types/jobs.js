"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
function isMlJob(arg) {
    return typeof arg.job_id === 'string';
}
exports.isMlJob = isMlJob;
function isMlJobs(arg) {
    if (Array.isArray(arg) === false) {
        return false;
    }
    return arg.every((d) => isMlJob(d));
}
exports.isMlJobs = isMlJobs;

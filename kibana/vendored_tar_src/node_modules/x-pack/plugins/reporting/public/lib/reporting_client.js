"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const kfetch_1 = require("ui/kfetch");
// @ts-ignore
const rison_node_1 = tslib_1.__importDefault(require("rison-node"));
const chrome_1 = tslib_1.__importDefault(require("ui/chrome"));
const query_string_1 = require("ui/utils/query_string");
const job_completion_notifications_1 = require("./job_completion_notifications");
const API_BASE_URL = '/api/reporting/generate';
class ReportingClient {
    constructor() {
        this.getReportingJobPath = (exportType, jobParams) => {
            return `${chrome_1.default.addBasePath(API_BASE_URL)}/${exportType}?${query_string_1.QueryString.param('jobParams', rison_node_1.default.encode(jobParams))}`;
        };
        this.createReportingJob = async (exportType, jobParams) => {
            const query = {
                jobParams: rison_node_1.default.encode(jobParams),
            };
            const resp = await kfetch_1.kfetch({ method: 'POST', pathname: `${API_BASE_URL}/${exportType}`, query });
            job_completion_notifications_1.jobCompletionNotifications.add(resp.job.id);
            return resp;
        };
    }
}
exports.reportingClient = new ReportingClient();

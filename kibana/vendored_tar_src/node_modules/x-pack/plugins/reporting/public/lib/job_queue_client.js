"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const kfetch_1 = require("ui/kfetch");
// @ts-ignore
const system_api_1 = require("ui/system_api");
const API_BASE_URL = '/api/reporting/jobs';
class JobQueueClient {
    constructor() {
        this.list = (page = 0, jobIds) => {
            const query = { page };
            if (jobIds && jobIds.length > 0) {
                // Only getting the first 10, to prevent URL overflows
                query.ids = jobIds.slice(0, 10).join(',');
            }
            return kfetch_1.kfetch({
                method: 'GET',
                pathname: `${API_BASE_URL}/list`,
                query,
                headers: system_api_1.addSystemApiHeader({}),
            });
        };
    }
    total() {
        return kfetch_1.kfetch({
            method: 'GET',
            pathname: `${API_BASE_URL}/count`,
            headers: system_api_1.addSystemApiHeader({}),
        });
    }
    getContent(jobId) {
        return kfetch_1.kfetch({
            method: 'GET',
            pathname: `${API_BASE_URL}/output/${jobId}`,
            headers: system_api_1.addSystemApiHeader({}),
        });
    }
    getInfo(jobId) {
        return kfetch_1.kfetch({
            method: 'GET',
            pathname: `${API_BASE_URL}/info/${jobId}`,
            headers: system_api_1.addSystemApiHeader({}),
        });
    }
}
exports.jobQueueClient = new JobQueueClient();

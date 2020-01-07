"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const chrome_1 = tslib_1.__importDefault(require("ui/chrome"));
const constants_1 = require("../../common/constants");
function downloadReport(jobId) {
    const apiBaseUrl = chrome_1.default.addBasePath(constants_1.API_BASE_URL);
    const downloadLink = `${apiBaseUrl}/jobs/download/${jobId}`;
    window.open(downloadLink);
}
exports.downloadReport = downloadReport;

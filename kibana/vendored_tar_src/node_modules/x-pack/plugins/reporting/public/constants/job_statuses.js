"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
var JobStatuses;
(function (JobStatuses) {
    JobStatuses["PENDING"] = "pending";
    JobStatuses["PROCESSING"] = "processing";
    JobStatuses["COMPLETED"] = "completed";
    JobStatuses["FAILED"] = "failed";
    JobStatuses["CANCELLED"] = "cancelled";
})(JobStatuses = exports.JobStatuses || (exports.JobStatuses = {}));

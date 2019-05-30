"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const d3_time_format_1 = require("d3-time-format");
const formatDate = d3_time_format_1.timeFormat('%Y-%m-%d %H:%M:%S.%L');
function formatTime(time) {
    return formatDate(new Date(time));
}
exports.formatTime = formatTime;

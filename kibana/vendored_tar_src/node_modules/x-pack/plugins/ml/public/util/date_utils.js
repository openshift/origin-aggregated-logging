"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
// utility functions for handling dates
// @ts-ignore
const format_1 = require("@elastic/eui/lib/services/format");
function formatHumanReadableDate(ts) {
    return format_1.formatDate(ts, 'MMMM Do YYYY');
}
exports.formatHumanReadableDate = formatHumanReadableDate;
function formatHumanReadableDateTime(ts) {
    return format_1.formatDate(ts, 'MMMM Do YYYY, HH:mm');
}
exports.formatHumanReadableDateTime = formatHumanReadableDateTime;
function formatHumanReadableDateTimeSeconds(ts) {
    return format_1.formatDate(ts, 'MMMM Do YYYY, HH:mm:ss');
}
exports.formatHumanReadableDateTimeSeconds = formatHumanReadableDateTimeSeconds;

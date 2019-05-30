"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Returns a date that is the specified interval from now. Currently,
 * only minute-intervals are supported.
 *
 * @param {string} interval - An interval of the form `Nm` such as `5m`
 */
function intervalFromNow(interval) {
    if (interval === undefined) {
        return;
    }
    assertValidInterval(interval);
    return minutesFromNow(parseInterval(interval));
}
exports.intervalFromNow = intervalFromNow;
/**
 * Returns a date that is mins minutes from now.
 *
 * @param mins The number of mintues from now
 */
function minutesFromNow(mins) {
    const now = new Date();
    now.setMinutes(now.getMinutes() + mins);
    return now;
}
exports.minutesFromNow = minutesFromNow;
/**
 * Verifies that the specified interval matches our expected format.
 *
 * @param {string} interval - An interval such as `5m`
 */
function assertValidInterval(interval) {
    if (/^[0-9]+m$/.test(interval)) {
        return interval;
    }
    throw new Error(`Invalid interval "${interval}". Intervals must be of the form {number}m. Example: 5m.`);
}
exports.assertValidInterval = assertValidInterval;
function parseInterval(interval) {
    return parseInt(interval, 10);
}

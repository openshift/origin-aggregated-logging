"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const moment_1 = tslib_1.__importDefault(require("moment"));
// @ts-ignore
const calculate_auto_1 = require("./calculate_auto");
// @ts-ignore
const unit_to_seconds_1 = require("./unit_to_seconds");
function getBucketSize(start, end, interval) {
    const duration = moment_1.default.duration(end - start, 'ms');
    const bucketSize = Math.max(calculate_auto_1.calculateAuto.near(100, duration).asSeconds(), 1);
    const intervalString = `${bucketSize}s`;
    const matches = interval && interval.match(/^([\d]+)([shmdwMy]|ms)$/);
    const minBucketSize = matches
        ? Number(matches[1]) * unit_to_seconds_1.unitToSeconds(matches[2])
        : 0;
    if (bucketSize < minBucketSize) {
        return {
            bucketSize: minBucketSize,
            intervalString: interval
        };
    }
    return { bucketSize, intervalString };
}
exports.getBucketSize = getBucketSize;

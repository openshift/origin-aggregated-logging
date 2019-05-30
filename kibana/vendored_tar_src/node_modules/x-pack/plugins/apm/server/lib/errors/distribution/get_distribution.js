"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const get_buckets_1 = require("./get_buckets");
function getBucketSize({ start, end, config }) {
    const bucketTargetCount = config.get('xpack.apm.bucketTargetCount');
    return Math.floor((end - start) / bucketTargetCount);
}
async function getDistribution({ serviceName, groupId, setup }) {
    const bucketSize = getBucketSize(setup);
    const { buckets, totalHits } = await get_buckets_1.getBuckets({
        serviceName,
        groupId,
        bucketSize,
        setup
    });
    return {
        totalHits,
        buckets,
        bucketSize
    };
}
exports.getDistribution = getDistribution;

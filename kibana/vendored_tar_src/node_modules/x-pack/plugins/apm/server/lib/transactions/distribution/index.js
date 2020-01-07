"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const calculate_bucket_size_1 = require("./calculate_bucket_size");
const get_buckets_1 = require("./get_buckets");
async function getDistribution(serviceName, transactionName, transactionType, transactionId, traceId, setup) {
    const bucketSize = await calculate_bucket_size_1.calculateBucketSize(serviceName, transactionName, transactionType, setup);
    const { defaultSample, buckets, totalHits } = await get_buckets_1.getBuckets(serviceName, transactionName, transactionType, transactionId, traceId, bucketSize, setup);
    return {
        totalHits,
        buckets,
        bucketSize,
        defaultSample
    };
}
exports.getDistribution = getDistribution;

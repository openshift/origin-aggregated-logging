"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const fetcher_1 = require("./fetcher");
const transform_1 = require("./transform");
async function getBuckets(serviceName, transactionName, transactionType, transactionId, traceId, bucketSize, setup) {
    const response = await fetcher_1.bucketFetcher(serviceName, transactionName, transactionType, transactionId, traceId, bucketSize, setup);
    return transform_1.bucketTransformer(response);
}
exports.getBuckets = getBuckets;

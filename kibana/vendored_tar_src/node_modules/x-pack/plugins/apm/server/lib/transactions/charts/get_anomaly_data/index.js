"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const get_bucket_size_1 = require("../../../helpers/get_bucket_size");
const fetcher_1 = require("./fetcher");
const get_ml_bucket_size_1 = require("./get_ml_bucket_size");
const transform_1 = require("./transform");
async function getAnomalySeries({ serviceName, transactionType, transactionName, timeSeriesDates, setup }) {
    // don't fetch anomalies for transaction details page
    if (transactionName) {
        return;
    }
    // don't fetch anomalies without a type
    if (!transactionType) {
        return;
    }
    const mlBucketSize = await get_ml_bucket_size_1.getMlBucketSize({
        serviceName,
        transactionType,
        setup
    });
    const { start, end } = setup;
    const { intervalString, bucketSize } = get_bucket_size_1.getBucketSize(start, end, 'auto');
    const esResponse = await fetcher_1.anomalySeriesFetcher({
        serviceName,
        transactionType,
        intervalString,
        mlBucketSize,
        setup
    });
    return transform_1.anomalySeriesTransform(esResponse, mlBucketSize, bucketSize, timeSeriesDates);
}
exports.getAnomalySeries = getAnomalySeries;

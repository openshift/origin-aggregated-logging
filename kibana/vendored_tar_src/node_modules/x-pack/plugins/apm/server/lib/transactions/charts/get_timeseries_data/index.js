"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const get_bucket_size_1 = require("../../../helpers/get_bucket_size");
const fetcher_1 = require("./fetcher");
const transform_1 = require("./transform");
async function getApmTimeseriesData(options) {
    const { start, end } = options.setup;
    const { bucketSize } = get_bucket_size_1.getBucketSize(start, end, 'auto');
    const timeseriesResponse = await fetcher_1.timeseriesFetcher(options);
    return transform_1.timeseriesTransformer({
        timeseriesResponse,
        bucketSize
    });
}
exports.getApmTimeseriesData = getApmTimeseriesData;

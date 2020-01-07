"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adapter_types_1 = require("../../adapter_types");
exports.hostFilesystem = (timeField, indexPattern, interval) => ({
    id: 'hostFilesystem',
    requires: ['system.filesystem'],
    filter: 'system.filesystem.device_name:\\/*',
    index_pattern: indexPattern,
    time_field: timeField,
    interval,
    type: 'timeseries',
    series: [
        {
            id: 'used',
            metrics: [
                {
                    field: 'system.filesystem.used.pct',
                    id: 'avg-filesystem-used',
                    type: adapter_types_1.InfraMetricModelMetricType.avg,
                },
            ],
            split_mode: 'terms',
            terms_field: 'system.filesystem.device_name',
            terms_order_by: 'used',
            terms_size: 5,
        },
    ],
});

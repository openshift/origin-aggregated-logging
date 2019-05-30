"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adapter_types_1 = require("../../adapter_types");
exports.podLogUsage = (timeField, indexPattern, interval) => ({
    id: 'podLogUsage',
    requires: ['kubernetes.pod'],
    index_pattern: indexPattern,
    interval,
    time_field: timeField,
    type: 'timeseries',
    series: [
        {
            id: 'logs',
            split_mode: 'everything',
            metrics: [
                {
                    field: 'kubernetes.container.logs.used.bytes',
                    id: 'avg-log-used',
                    type: adapter_types_1.InfraMetricModelMetricType.avg,
                },
                {
                    field: 'kubernetes.container.logs.capacity.bytes',
                    id: 'max-log-cap',
                    type: adapter_types_1.InfraMetricModelMetricType.max,
                },
                {
                    id: 'calc-usage-limit',
                    script: 'params.usage / params.limit',
                    type: adapter_types_1.InfraMetricModelMetricType.calculation,
                    variables: [
                        {
                            field: 'avg-log-userd',
                            id: 'var-usage',
                            name: 'usage',
                        },
                        {
                            field: 'max-log-cap',
                            id: 'var-limit',
                            name: 'limit',
                        },
                    ],
                },
            ],
        },
    ],
});

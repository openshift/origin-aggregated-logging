"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adapter_types_1 = require("../../adapter_types");
exports.nginxRequestRate = (timeField, indexPattern, interval) => ({
    id: 'nginxRequestRate',
    requires: ['nginx.stubstatus'],
    index_pattern: indexPattern,
    interval,
    time_field: timeField,
    type: 'timeseries',
    series: [
        {
            id: 'rate',
            metrics: [
                {
                    field: 'nginx.stubstatus.requests',
                    id: 'max-requests',
                    type: adapter_types_1.InfraMetricModelMetricType.max,
                },
                {
                    field: 'max-requests',
                    id: 'derv-max-requests',
                    type: adapter_types_1.InfraMetricModelMetricType.derivative,
                    unit: '1s',
                },
                {
                    id: 'posonly-derv-max-requests',
                    type: adapter_types_1.InfraMetricModelMetricType.calculation,
                    variables: [{ id: 'var-rate', name: 'rate', field: 'derv-max-requests' }],
                    script: 'params.rate > 0.0 ? params.rate : 0.0',
                },
            ],
            split_mode: 'everything',
        },
    ],
});

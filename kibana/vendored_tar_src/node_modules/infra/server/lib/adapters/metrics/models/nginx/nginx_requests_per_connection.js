"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adapter_types_1 = require("../../adapter_types");
exports.nginxRequestsPerConnection = (timeField, indexPattern, interval) => ({
    id: 'nginxRequestsPerConnection',
    requires: ['nginx.stubstatus'],
    index_pattern: indexPattern,
    interval,
    time_field: timeField,
    type: 'timeseries',
    series: [
        {
            id: 'reqPerConns',
            metrics: [
                {
                    field: 'nginx.stubstatus.handled',
                    id: 'max-handled',
                    type: adapter_types_1.InfraMetricModelMetricType.max,
                },
                {
                    field: 'nginx.stubstatus.requests',
                    id: 'max-requests',
                    type: adapter_types_1.InfraMetricModelMetricType.max,
                },
                {
                    id: 'reqs-per-connection',
                    type: adapter_types_1.InfraMetricModelMetricType.calculation,
                    variables: [
                        { id: 'var-handled', name: 'handled', field: 'max-handled' },
                        { id: 'var-requests', name: 'requests', field: 'max-requests' },
                    ],
                    script: 'params.handled > 0.0 && params.requests > 0.0 ? params.handled / params.requests : 0.0',
                },
            ],
            split_mode: 'everything',
        },
    ],
});

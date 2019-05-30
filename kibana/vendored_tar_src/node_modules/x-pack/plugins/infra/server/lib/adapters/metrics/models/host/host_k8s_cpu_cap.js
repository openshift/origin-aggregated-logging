"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adapter_types_1 = require("../../adapter_types");
exports.hostK8sCpuCap = (timeField, indexPattern, interval) => ({
    id: 'hostK8sCpuCap',
    map_field_to: 'kubernetes.node.name',
    requires: ['kubernetes.node'],
    index_pattern: indexPattern,
    interval,
    time_field: timeField,
    type: 'timeseries',
    series: [
        {
            id: 'capacity',
            metrics: [
                {
                    field: 'kubernetes.node.cpu.allocatable.cores',
                    id: 'max-cpu-cap',
                    type: adapter_types_1.InfraMetricModelMetricType.max,
                },
                {
                    id: 'calc-nanocores',
                    type: adapter_types_1.InfraMetricModelMetricType.calculation,
                    variables: [
                        {
                            id: 'var-cores',
                            field: 'max-cpu-cap',
                            name: 'cores',
                        },
                    ],
                    script: 'params.cores * 1000000000',
                },
            ],
            split_mode: 'everything',
        },
        {
            id: 'used',
            metrics: [
                {
                    field: 'kubernetes.node.cpu.usage.nanocores',
                    id: 'avg-cpu-usage',
                    type: adapter_types_1.InfraMetricModelMetricType.avg,
                },
            ],
            split_mode: 'everything',
        },
    ],
});

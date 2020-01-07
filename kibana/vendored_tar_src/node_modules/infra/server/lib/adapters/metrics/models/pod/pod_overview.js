"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adapter_types_1 = require("../../adapter_types");
exports.podOverview = (timeField, indexPattern, interval) => ({
    id: 'podOverview',
    requires: ['kubernetes.pod'],
    index_pattern: indexPattern,
    interval,
    time_field: timeField,
    type: 'timeseries',
    series: [
        {
            id: 'cpu',
            split_mode: 'everything',
            metrics: [
                {
                    field: 'kubernetes.pod.cpu.usage.node.pct',
                    id: 'avg-cpu-usage',
                    type: adapter_types_1.InfraMetricModelMetricType.avg,
                },
            ],
        },
        {
            id: 'memory',
            split_mode: 'everything',
            metrics: [
                {
                    field: 'kubernetes.pod.memory.usage.node.pct',
                    id: 'avg-memory-usage',
                    type: adapter_types_1.InfraMetricModelMetricType.avg,
                },
            ],
        },
        {
            id: 'rx',
            split_mode: 'everything',
            metrics: [
                {
                    field: 'kubernetes.pod.network.rx.bytes',
                    id: 'max-network-rx',
                    type: adapter_types_1.InfraMetricModelMetricType.max,
                },
                {
                    field: 'max-network-rx',
                    id: 'deriv-max-network-rx',
                    type: adapter_types_1.InfraMetricModelMetricType.derivative,
                    unit: '1s',
                },
                {
                    id: 'posonly-deriv-max-network-rx',
                    type: adapter_types_1.InfraMetricModelMetricType.calculation,
                    variables: [{ id: 'var-rate', name: 'rate', field: 'deriv-max-network-rx' }],
                    script: 'params.rate > 0.0 ? params.rate : 0.0',
                },
            ],
        },
        {
            id: 'tx',
            split_mode: 'everything',
            metrics: [
                {
                    field: 'kubernetes.pod.network.tx.bytes',
                    id: 'max-network-tx',
                    type: adapter_types_1.InfraMetricModelMetricType.max,
                },
                {
                    field: 'max-network-tx',
                    id: 'deriv-max-network-tx',
                    type: adapter_types_1.InfraMetricModelMetricType.derivative,
                    unit: '1s',
                },
                {
                    id: 'posonly-deriv-max-network-tx',
                    type: adapter_types_1.InfraMetricModelMetricType.calculation,
                    variables: [{ id: 'var-rate', name: 'rate', field: 'deriv-max-network-tx' }],
                    script: 'params.rate > 0.0 ? params.rate : 0.0',
                },
            ],
        },
    ],
});

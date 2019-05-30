"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adapter_types_1 = require("../../adapter_types");
exports.podNetworkTraffic = (timeField, indexPattern, interval) => ({
    id: 'podNetworkTraffic',
    requires: ['kubernetes.pod'],
    index_pattern: indexPattern,
    interval,
    time_field: timeField,
    type: 'timeseries',
    series: [
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
                    id: 'posonly-deriv-max-net-tx',
                    type: adapter_types_1.InfraMetricModelMetricType.calculation,
                    variables: [{ id: 'var-rate', name: 'rate', field: 'deriv-max-network-tx' }],
                    script: 'params.rate > 0.0 ? params.rate : 0.0',
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
                    id: 'posonly-deriv-max-net-tx',
                    type: adapter_types_1.InfraMetricModelMetricType.calculation,
                    variables: [{ id: 'var-rate', name: 'rate', field: 'deriv-max-network-tx' }],
                    script: 'params.rate > 0.0 ? params.rate : 0.0',
                },
                {
                    id: 'invert-posonly-deriv-max-network-rx',
                    script: 'params.rate * -1',
                    type: adapter_types_1.InfraMetricModelMetricType.calculation,
                    variables: [
                        {
                            field: 'posonly-deriv-max-network-rx',
                            id: 'var-rate',
                            name: 'rate',
                        },
                    ],
                },
            ],
        },
    ],
});

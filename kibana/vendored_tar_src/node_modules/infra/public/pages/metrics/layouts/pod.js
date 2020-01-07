"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const i18n_1 = require("@kbn/i18n");
const types_1 = require("../../../graphql/types");
const lib_1 = require("../../../lib/lib");
const nginx_1 = require("./nginx");
const types_2 = require("./types");
exports.podLayoutCreator = theme => [
    {
        id: 'podOverview',
        label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.podMetricsLayout.layoutLabel', {
            defaultMessage: 'Pod',
        }),
        sections: [
            {
                id: types_1.InfraMetric.podOverview,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.podMetricsLayout.overviewSection.sectionLabel', {
                    defaultMessage: 'Overview',
                }),
                requires: ['kubernetes.pod'],
                type: types_2.InfraMetricLayoutSectionType.gauges,
                visConfig: {
                    seriesOverrides: {
                        cpu: {
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.podMetricsLayout.overviewSection.cpuUsageSeriesLabel', {
                                defaultMessage: 'CPU Usage',
                            }),
                            color: theme.eui.euiColorFullShade,
                            formatter: lib_1.InfraFormatterType.percent,
                            gaugeMax: 1,
                        },
                        memory: {
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.podMetricsLayout.overviewSection.memoryUsageSeriesLabel', {
                                defaultMessage: 'Memory Usage',
                            }),
                            color: theme.eui.euiColorFullShade,
                            formatter: lib_1.InfraFormatterType.percent,
                            gaugeMax: 1,
                        },
                        rx: {
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.podMetricsLayout.overviewSection.inboundRXSeriesLabel', {
                                defaultMessage: 'Inbound (RX)',
                            }),
                            color: theme.eui.euiColorFullShade,
                            formatter: lib_1.InfraFormatterType.bits,
                            formatterTemplate: '{{value}}/s',
                        },
                        tx: {
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.podMetricsLayout.overviewSection.outboundTXSeriesLabel', {
                                defaultMessage: 'Outbound (TX)',
                            }),
                            color: theme.eui.euiColorFullShade,
                            formatter: lib_1.InfraFormatterType.bits,
                            formatterTemplate: '{{value}}/s',
                        },
                    },
                },
            },
            {
                id: types_1.InfraMetric.podCpuUsage,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.podMetricsLayout.cpuUsageSection.sectionLabel', {
                    defaultMessage: 'CPU Usage',
                }),
                requires: ['kubernetes.pod'],
                type: types_2.InfraMetricLayoutSectionType.chart,
                visConfig: {
                    formatter: lib_1.InfraFormatterType.percent,
                    seriesOverrides: {
                        cpu: { color: theme.eui.euiColorVis1, type: types_2.InfraMetricLayoutVisualizationType.area },
                    },
                },
            },
            {
                id: types_1.InfraMetric.podMemoryUsage,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.podMetricsLayout.memoryUsageSection.sectionLabel', {
                    defaultMessage: 'Memory Usage',
                }),
                requires: ['kubernetes.pod'],
                type: types_2.InfraMetricLayoutSectionType.chart,
                visConfig: {
                    formatter: lib_1.InfraFormatterType.percent,
                    seriesOverrides: {
                        memory: {
                            color: theme.eui.euiColorVis1,
                            type: types_2.InfraMetricLayoutVisualizationType.area,
                        },
                    },
                },
            },
            {
                id: types_1.InfraMetric.podNetworkTraffic,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.podMetricsLayout.networkTrafficSection.sectionLabel', {
                    defaultMessage: 'Network Traffic',
                }),
                requires: ['kubernetes.pod'],
                type: types_2.InfraMetricLayoutSectionType.chart,
                visConfig: {
                    formatter: lib_1.InfraFormatterType.bits,
                    formatterTemplate: '{{value}}/s',
                    type: types_2.InfraMetricLayoutVisualizationType.area,
                    seriesOverrides: {
                        rx: {
                            color: theme.eui.euiColorVis1,
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.podMetricsLayout.networkTrafficSection.networkRxRateSeriesLabel', {
                                defaultMessage: 'in',
                            }),
                        },
                        tx: {
                            color: theme.eui.euiColorVis2,
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.podMetricsLayout.networkTrafficSection.networkTxRateSeriesLabel', {
                                defaultMessage: 'out',
                            }),
                        },
                    },
                },
            },
        ],
    },
    ...nginx_1.nginxLayoutCreator(theme),
];

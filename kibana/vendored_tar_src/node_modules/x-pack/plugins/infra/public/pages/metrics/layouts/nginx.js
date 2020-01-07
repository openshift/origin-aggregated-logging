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
const types_2 = require("./types");
exports.nginxLayoutCreator = theme => [
    {
        id: 'nginxOverview',
        label: 'Nginx',
        requires: ['nginx'],
        sections: [
            {
                id: types_1.InfraMetric.nginxHits,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.nginxMetricsLayout.hitsSection.sectionLabel', {
                    defaultMessage: 'Hits',
                }),
                requires: ['nginx.access'],
                type: types_2.InfraMetricLayoutSectionType.chart,
                visConfig: {
                    formatter: lib_1.InfraFormatterType.abbreviatedNumber,
                    stacked: true,
                    seriesOverrides: {
                        '200s': { color: theme.eui.euiColorVis1, type: types_2.InfraMetricLayoutVisualizationType.bar },
                        '300s': { color: theme.eui.euiColorVis5, type: types_2.InfraMetricLayoutVisualizationType.bar },
                        '400s': { color: theme.eui.euiColorVis2, type: types_2.InfraMetricLayoutVisualizationType.bar },
                        '500s': { color: theme.eui.euiColorVis9, type: types_2.InfraMetricLayoutVisualizationType.bar },
                    },
                },
            },
            {
                id: types_1.InfraMetric.nginxRequestRate,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.nginxMetricsLayout.requestRateSection.sectionLabel', {
                    defaultMessage: 'Request Rate',
                }),
                requires: ['nginx.stubstatus'],
                type: types_2.InfraMetricLayoutSectionType.chart,
                visConfig: {
                    formatter: lib_1.InfraFormatterType.abbreviatedNumber,
                    formatterTemplate: '{{value}}/s',
                    seriesOverrides: {
                        rate: { color: theme.eui.euiColorVis1, type: types_2.InfraMetricLayoutVisualizationType.area },
                    },
                },
            },
            {
                id: types_1.InfraMetric.nginxActiveConnections,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.nginxMetricsLayout.activeConnectionsSection.sectionLabel', {
                    defaultMessage: 'Active Connections',
                }),
                requires: ['nginx.stubstatus'],
                type: types_2.InfraMetricLayoutSectionType.chart,
                visConfig: {
                    formatter: lib_1.InfraFormatterType.abbreviatedNumber,
                    seriesOverrides: {
                        connections: {
                            color: theme.eui.euiColorVis1,
                            type: types_2.InfraMetricLayoutVisualizationType.bar,
                        },
                    },
                },
            },
            {
                id: types_1.InfraMetric.nginxRequestsPerConnection,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.nginxMetricsLayout.requestsPerConnectionsSection.sectionLabel', {
                    defaultMessage: 'Requests per Connections',
                }),
                requires: ['nginx.stubstatus'],
                type: types_2.InfraMetricLayoutSectionType.chart,
                visConfig: {
                    formatter: lib_1.InfraFormatterType.abbreviatedNumber,
                    seriesOverrides: {
                        reqPerConns: {
                            color: theme.eui.euiColorVis1,
                            type: types_2.InfraMetricLayoutVisualizationType.bar,
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.nginxMetricsLayout.requestsPerConnectionsSection.reqsPerConnSeriesLabel', {
                                defaultMessage: 'reqs per conn',
                            }),
                        },
                    },
                },
            },
        ],
    },
];

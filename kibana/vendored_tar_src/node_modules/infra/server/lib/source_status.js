"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class InfraSourceStatus {
    constructor(adapter, libs) {
        this.adapter = adapter;
        this.libs = libs;
    }
    async getLogIndexNames(request, sourceId) {
        const sourceConfiguration = await this.libs.sources.getSourceConfiguration(request, sourceId);
        const indexNames = await this.adapter.getIndexNames(request, sourceConfiguration.configuration.logAlias);
        return indexNames;
    }
    async getMetricIndexNames(request, sourceId) {
        const sourceConfiguration = await this.libs.sources.getSourceConfiguration(request, sourceId);
        const indexNames = await this.adapter.getIndexNames(request, sourceConfiguration.configuration.metricAlias);
        return indexNames;
    }
    async hasLogAlias(request, sourceId) {
        const sourceConfiguration = await this.libs.sources.getSourceConfiguration(request, sourceId);
        const hasAlias = await this.adapter.hasAlias(request, sourceConfiguration.configuration.logAlias);
        return hasAlias;
    }
    async hasMetricAlias(request, sourceId) {
        const sourceConfiguration = await this.libs.sources.getSourceConfiguration(request, sourceId);
        const hasAlias = await this.adapter.hasAlias(request, sourceConfiguration.configuration.metricAlias);
        return hasAlias;
    }
    async hasLogIndices(request, sourceId) {
        const sourceConfiguration = await this.libs.sources.getSourceConfiguration(request, sourceId);
        const hasIndices = await this.adapter.hasIndices(request, sourceConfiguration.configuration.logAlias);
        return hasIndices;
    }
    async hasMetricIndices(request, sourceId) {
        const sourceConfiguration = await this.libs.sources.getSourceConfiguration(request, sourceId);
        const hasIndices = await this.adapter.hasIndices(request, sourceConfiguration.configuration.metricAlias);
        return hasIndices;
    }
}
exports.InfraSourceStatus = InfraSourceStatus;

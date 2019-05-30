"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const types_1 = require("../../graphql/types");
class InfraFieldsDomain {
    constructor(adapter, libs) {
        this.adapter = adapter;
        this.libs = libs;
    }
    async getFields(request, sourceId, indexType) {
        const { configuration } = await this.libs.sources.getSourceConfiguration(request, sourceId);
        const includeMetricIndices = [types_1.InfraIndexType.ANY, types_1.InfraIndexType.METRICS].includes(indexType);
        const includeLogIndices = [types_1.InfraIndexType.ANY, types_1.InfraIndexType.LOGS].includes(indexType);
        const fields = await this.adapter.getIndexFields(request, `${includeMetricIndices ? configuration.metricAlias : ''},${includeLogIndices ? configuration.logAlias : ''}`);
        return fields;
    }
}
exports.InfraFieldsDomain = InfraFieldsDomain;

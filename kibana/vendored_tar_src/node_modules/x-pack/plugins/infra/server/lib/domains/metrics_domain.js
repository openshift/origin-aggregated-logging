"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class InfraMetricsDomain {
    constructor(adapter) {
        this.adapter = adapter;
    }
    async getMetrics(req, options) {
        return await this.adapter.getMetrics(req, options);
    }
}
exports.InfraMetricsDomain = InfraMetricsDomain;

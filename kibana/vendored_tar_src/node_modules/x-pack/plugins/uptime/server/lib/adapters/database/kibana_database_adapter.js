"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class UMKibanaDatabaseAdapter {
    constructor(kbnElasticsearch) {
        this.elasticsearch = kbnElasticsearch.getCluster('data');
    }
    async search(request, params) {
        return this.elasticsearch.callWithRequest(request, 'search', params);
    }
    async count(request, params) {
        return this.elasticsearch.callWithRequest(request, 'count', params);
    }
}
exports.UMKibanaDatabaseAdapter = UMKibanaDatabaseAdapter;

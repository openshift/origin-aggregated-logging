"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class RestConfigBlocksAdapter {
    constructor(REST) {
        this.REST = REST;
    }
    async upsert(blocks) {
        const result = await this.REST.put(`/api/beats/configurations`, blocks);
        return result;
    }
    async getForTags(tagIds, page) {
        return await this.REST.get(`/api/beats/configurations/${tagIds.join(',')}/${page}`);
    }
    async delete(id) {
        return (await this.REST.delete(`/api/beats/configurations/${id}`))
            .success;
    }
}
exports.RestConfigBlocksAdapter = RestConfigBlocksAdapter;

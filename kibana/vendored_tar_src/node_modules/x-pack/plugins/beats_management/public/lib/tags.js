"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const v4_1 = tslib_1.__importDefault(require("uuid/v4"));
class TagsLib {
    constructor(adapter, elasticsearch) {
        this.adapter = adapter;
        this.elasticsearch = elasticsearch;
    }
    async getTagsWithIds(tagIds) {
        if (tagIds.length === 0) {
            return [];
        }
        return await this.adapter.getTagsWithIds([...new Set(tagIds)]);
    }
    async delete(tagIds) {
        return await this.adapter.delete([...new Set(tagIds)]);
    }
    // FIXME: This needs to be paginated https://github.com/elastic/kibana/issues/26022
    async getAll(kuery) {
        let ESQuery;
        if (kuery) {
            ESQuery = await this.elasticsearch.convertKueryToEsQuery(kuery);
        }
        return await this.adapter.getAll(ESQuery);
    }
    async upsertTag(tag) {
        if (!tag.id) {
            tag.id = v4_1.default();
        }
        return await this.adapter.upsertTag(tag);
    }
    async getassignableTagsForBeats(beats) {
        return await this.adapter.getAssignable(beats);
    }
}
exports.TagsLib = TagsLib;

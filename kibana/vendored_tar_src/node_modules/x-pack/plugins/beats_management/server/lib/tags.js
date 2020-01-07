"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const lodash_1 = require("lodash");
const configuration_blocks_1 = require("../../common/constants/configuration_blocks");
class CMTagsDomain {
    constructor(adapter, configurationBlocksAdapter, beatsAdabter) {
        this.adapter = adapter;
        this.configurationBlocksAdapter = configurationBlocksAdapter;
        this.beatsAdabter = beatsAdabter;
    }
    async getAll(user, ESQuery) {
        const tags = await this.adapter.getAll(user, ESQuery);
        return tags;
    }
    async getWithIds(user, tagIds) {
        const tags = await this.adapter.getTagsWithIds(user, tagIds);
        return tags;
    }
    async delete(user, tagIds) {
        const beats = await this.beatsAdabter.getAllWithTags(user, tagIds);
        if (beats.filter(b => b.active).length > 0) {
            return false;
        }
        await this.configurationBlocksAdapter.deleteForTags(user, tagIds);
        return await this.adapter.delete(user, tagIds);
    }
    async getNonConflictingTags(user, existingTagIds) {
        const tags = await this.adapter.getTagsWithIds(user, existingTagIds);
        const existingUniqueBlockTypes = lodash_1.uniq(tags.reduce((existingUniqueTypes, tag) => {
            if (tag.hasConfigurationBlocksTypes) {
                existingUniqueTypes = existingUniqueTypes.concat(tag.hasConfigurationBlocksTypes);
            }
            return existingUniqueTypes;
        }, [])).filter(type => configuration_blocks_1.UNIQUENESS_ENFORCING_TYPES.includes(type));
        const safeTags = await this.adapter.getWithoutConfigTypes(user, existingUniqueBlockTypes);
        return safeTags;
    }
    async upsertTag(user, tag) {
        const tagId = await this.adapter.upsertTag(user, tag);
        return tagId;
    }
}
exports.CMTagsDomain = CMTagsDomain;

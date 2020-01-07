"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const configuration_blocks_1 = require("../../common/constants/configuration_blocks");
class ConfigurationBlocksLib {
    constructor(adapter, tags) {
        this.adapter = adapter;
        this.tags = tags;
    }
    async getForTags(user, tagIds, page = 0, size = 10) {
        if ((page + 1) * size > 10000) {
            throw new Error('System error, too many results. To get all results, request page: -1');
        }
        const result = await this.adapter.getForTags(user, tagIds, page, size);
        return { ...result, error: null };
    }
    async delete(user, ids) {
        return await this.adapter.delete(user, ids);
    }
    async save(user, block) {
        const tags = await this.tags.getWithIds(user, [block.tag]);
        const tag = tags[0];
        if (!tag) {
            return {
                error: 'Invalid tag, tag not found',
            };
        }
        if (!tag.hasConfigurationBlocksTypes) {
            tag.hasConfigurationBlocksTypes = [];
        }
        if (!block.id &&
            configuration_blocks_1.UNIQUENESS_ENFORCING_TYPES.includes(block.type) &&
            tag.hasConfigurationBlocksTypes.some((type) => configuration_blocks_1.UNIQUENESS_ENFORCING_TYPES.includes(type))) {
            return {
                error: 'Block is of type that already exists on this tag, and only one config of this type can exist at a time on a beat. Config not saved',
            };
        }
        if (configuration_blocks_1.UNIQUENESS_ENFORCING_TYPES.includes(block.type)) {
            tag.hasConfigurationBlocksTypes.push(block.type);
            await this.tags.upsertTag(user, tag);
        }
        const ids = await this.adapter.create(user, [block]);
        return {
            success: true,
            blockID: ids[0],
        };
    }
}
exports.ConfigurationBlocksLib = ConfigurationBlocksLib;

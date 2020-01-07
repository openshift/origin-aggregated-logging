"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const chance_1 = tslib_1.__importDefault(require("chance")); // eslint-disable-line
const chance = new chance_1.default();
class MemoryConfigurationBlockAdapter {
    constructor(db) {
        this.db = [];
        this.db = db.map(config => {
            if (config.id === undefined) {
                config.id = chance.word();
            }
            return config;
        });
    }
    async getByIds(user, ids) {
        return this.db.filter(block => ids.includes(block.id));
    }
    async delete(user, blockIds) {
        this.db = this.db.filter(block => !blockIds.includes(block.id));
        return blockIds.map(id => ({
            id,
            success: true,
        }));
    }
    async deleteForTags(user, tagIds) {
        this.db = this.db.filter(block => !tagIds.includes(block.tag));
        return {
            success: true,
        };
    }
    async getForTags(user, tagIds, page, size) {
        const results = this.db.filter(block => tagIds.includes(block.id));
        return {
            page: 0,
            total: results.length,
            blocks: results,
        };
    }
    async create(user, blocks) {
        return blocks.map(block => {
            const existingIndex = this.db.findIndex(t => t.id === block.id);
            if (existingIndex !== -1) {
                this.db[existingIndex] = block;
            }
            else {
                this.db.push(block);
            }
            return block.id;
        });
    }
    setDB(db) {
        this.db = db.map(block => {
            if (block.id === undefined) {
                block.id = chance.word();
            }
            return block;
        });
    }
}
exports.MemoryConfigurationBlockAdapter = MemoryConfigurationBlockAdapter;

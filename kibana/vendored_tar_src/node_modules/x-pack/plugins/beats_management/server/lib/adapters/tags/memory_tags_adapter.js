"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class MemoryTagsAdapter {
    constructor(tagsDB) {
        this.tagsDB = [];
        this.tagsDB = tagsDB;
    }
    async getAll(user) {
        return this.tagsDB;
    }
    async delete(user, tagIds) {
        this.tagsDB = this.tagsDB.filter(tag => !tagIds.includes(tag.id));
        return true;
    }
    async getTagsWithIds(user, tagIds) {
        return this.tagsDB.filter(tag => tagIds.includes(tag.id));
    }
    async upsertTag(user, tag) {
        const existingTagIndex = this.tagsDB.findIndex(t => t.id === tag.id);
        if (existingTagIndex !== -1) {
            this.tagsDB[existingTagIndex] = tag;
        }
        else {
            this.tagsDB.push(tag);
        }
        return tag.id;
    }
    async getWithoutConfigTypes(user, blockTypes) {
        return this.tagsDB.filter(tag => tag.hasConfigurationBlocksTypes.includes(blockTypes[0]));
    }
    setDB(tagsDB) {
        this.tagsDB = tagsDB;
    }
}
exports.MemoryTagsAdapter = MemoryTagsAdapter;

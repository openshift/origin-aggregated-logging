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
    async getTagsWithIds(tagIds) {
        return this.tagsDB.filter(tag => tagIds.includes(tag.id));
    }
    async delete(tagIds) {
        this.tagsDB = this.tagsDB.filter(tag => !tagIds.includes(tag.id));
        return true;
    }
    async getAll(ESQuery) {
        return this.tagsDB;
    }
    async upsertTag(tag) {
        const existingTagIndex = this.tagsDB.findIndex(t => t.id === tag.id);
        if (existingTagIndex !== -1) {
            this.tagsDB[existingTagIndex] = tag;
        }
        else {
            this.tagsDB.push(tag);
        }
        return tag;
    }
    async getAssignable(beats) {
        return this.tagsDB;
    }
}
exports.MemoryTagsAdapter = MemoryTagsAdapter;

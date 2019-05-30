"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const unstated_1 = require("unstated");
class TagsContainer extends unstated_1.Container {
    constructor(libs) {
        super();
        this.libs = libs;
        this.reload = async (kuery) => {
            if (kuery) {
                this.query = kuery;
            }
            else {
                this.query = undefined;
            }
            const tags = await this.libs.tags.getAll(this.query);
            this.setState({
                list: tags,
            });
        };
        this.delete = async (tags) => {
            const tagIds = tags.map((tag) => tag.id);
            const success = await this.libs.tags.delete(tagIds);
            if (success) {
                this.setState({
                    list: this.state.list.filter(tag => tagIds.includes(tag.id)),
                });
            }
            return success;
        };
        this.upsertTag = async (tag) => {
            const beatTag = await this.libs.tags.upsertTag(tag);
            await this.reload();
            return beatTag !== null;
        };
        this.state = {
            list: [],
        };
    }
}
exports.TagsContainer = TagsContainer;

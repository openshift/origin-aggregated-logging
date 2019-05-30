"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class BeatsLib {
    constructor(adapter, elasticsearch) {
        this.adapter = adapter;
        this.elasticsearch = elasticsearch;
        /** Get a single beat using the token it was enrolled in for lookup */
        this.getBeatWithToken = async (enrollmentToken) => {
            const beat = await this.adapter.getBeatWithToken(enrollmentToken);
            return beat;
        };
        /** Get an array of beats that have a given tag id assigned to it */
        this.getBeatsWithTag = async (tagId) => {
            const beats = await this.adapter.getBeatsWithTag(tagId);
            return beats;
        };
        // FIXME: This needs to be paginated https://github.com/elastic/kibana/issues/26022
        /** Get an array of all enrolled beats. */
        this.getAll = async (kuery) => {
            let ESQuery;
            if (kuery) {
                ESQuery = await this.elasticsearch.convertKueryToEsQuery(kuery);
            }
            const beats = await this.adapter.getAll(ESQuery);
            return beats;
        };
        /** Update a given beat via it's ID */
        this.update = async (id, beatData) => {
            return await this.adapter.update(id, beatData);
        };
        /** unassign tags from beats using an array of tags and beats */
        this.removeTagsFromBeats = async (removals) => {
            return await this.adapter.removeTagsFromBeats(removals);
        };
        /** assign tags from beats using an array of tags and beats */
        this.assignTagsToBeats = async (assignments) => {
            return await this.adapter.assignTagsToBeats(assignments);
        };
    }
    /** Get a single beat using it's ID for lookup */
    async get(id) {
        const beat = await this.adapter.get(id);
        return beat;
    }
}
exports.BeatsLib = BeatsLib;

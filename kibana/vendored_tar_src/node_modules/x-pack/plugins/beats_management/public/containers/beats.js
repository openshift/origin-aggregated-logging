"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const unstated_1 = require("unstated");
class BeatsContainer extends unstated_1.Container {
    constructor(libs) {
        super();
        this.libs = libs;
        this.getBeatWithToken = async (token) => {
            const beat = await this.libs.beats.getBeatWithToken(token);
            if (beat) {
                this.setState({
                    list: [beat, ...this.state.list],
                });
                return beat;
            }
            return null;
        };
        this.reload = async (kuery) => {
            if (kuery) {
                this.query = kuery;
            }
            else {
                this.query = undefined;
            }
            const beats = await this.libs.beats.getAll(this.query);
            this.setState({
                list: beats,
            });
        };
        this.deactivate = async (beats) => {
            for (const beat of beats) {
                await this.libs.beats.update(beat.id, { active: false });
            }
            // because the compile code above has a very minor race condition, we wait,
            // the max race condition time is really 10ms but doing 100 to be safe
            setTimeout(async () => {
                await this.reload(this.query);
            }, 100);
        };
        this.toggleTagAssignment = async (tagId, beats) => {
            if (beats.some(beat => beat.tags !== undefined && beat.tags.some(id => id === tagId))) {
                await this.removeTagsFromBeats(beats, tagId);
                return 'removed';
            }
            await this.assignTagsToBeats(beats, tagId);
            return 'added';
        };
        this.removeTagsFromBeats = async (beats, tagId) => {
            if (!beats.length) {
                return false;
            }
            const assignments = createBeatTagAssignments(beats, tagId);
            await this.libs.beats.removeTagsFromBeats(assignments);
            // ES responds incorrectly when we call too soon
            setTimeout(async () => {
                await this.reload(this.query);
            }, 150);
        };
        this.assignTagsToBeats = async (beats, tagId) => {
            if (!beats.length) {
                return false;
            }
            const assignments = createBeatTagAssignments(beats, tagId);
            await this.libs.beats.assignTagsToBeats(assignments);
            // ES responds incorrectly when we call too soon
            setTimeout(async () => {
                await this.reload(this.query);
            }, 150);
        };
        this.state = {
            list: [],
        };
    }
}
exports.BeatsContainer = BeatsContainer;
function createBeatTagAssignments(beats, tagId) {
    if (typeof beats[0] === 'string') {
        return beats.map(id => ({ beatId: id, tag: tagId }));
    }
    else {
        return beats.map(({ id }) => ({ beatId: id, tag: tagId }));
    }
}

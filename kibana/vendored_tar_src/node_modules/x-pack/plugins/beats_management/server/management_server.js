"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const index_names_1 = require("../common/constants/index_names");
const index_templates_1 = require("./index_templates");
const configuration_1 = require("./rest_api/beats/configuration");
const enroll_1 = require("./rest_api/beats/enroll");
const events_1 = require("./rest_api/beats/events");
const get_1 = require("./rest_api/beats/get");
const list_1 = require("./rest_api/beats/list");
const tag_assignment_1 = require("./rest_api/beats/tag_assignment");
const tag_removal_1 = require("./rest_api/beats/tag_removal");
const update_1 = require("./rest_api/beats/update");
const delete_1 = require("./rest_api/configurations/delete");
const get_2 = require("./rest_api/configurations/get");
const upsert_1 = require("./rest_api/configurations/upsert");
const assignable_1 = require("./rest_api/tags/assignable");
const delete_2 = require("./rest_api/tags/delete");
const get_3 = require("./rest_api/tags/get");
const list_2 = require("./rest_api/tags/list");
const set_1 = require("./rest_api/tags/set");
const create_1 = require("./rest_api/tokens/create");
exports.initManagementServer = (libs) => {
    if (libs.database) {
        libs.framework.on('elasticsearch.status.green', async () => {
            await libs.database.putTemplate(index_names_1.INDEX_NAMES.BEATS, index_templates_1.beatsIndexTemplate);
        });
    }
    libs.framework.registerRoute(get_1.createGetBeatRoute(libs));
    libs.framework.registerRoute(get_3.createGetTagsWithIdsRoute(libs));
    libs.framework.registerRoute(list_2.createListTagsRoute(libs));
    libs.framework.registerRoute(delete_2.createDeleteTagsWithIdsRoute(libs));
    libs.framework.registerRoute(configuration_1.createGetBeatConfigurationRoute(libs));
    libs.framework.registerRoute(tag_assignment_1.createTagAssignmentsRoute(libs));
    libs.framework.registerRoute(list_1.createListAgentsRoute(libs));
    libs.framework.registerRoute(tag_removal_1.createTagRemovalsRoute(libs));
    libs.framework.registerRoute(enroll_1.createBeatEnrollmentRoute(libs));
    libs.framework.registerRoute(set_1.createSetTagRoute(libs));
    libs.framework.registerRoute(create_1.createTokensRoute(libs));
    libs.framework.registerRoute(update_1.createBeatUpdateRoute(libs));
    libs.framework.registerRoute(delete_1.createDeleteConfidurationsRoute(libs));
    libs.framework.registerRoute(get_2.createGetConfigurationBlocksRoute(libs));
    libs.framework.registerRoute(upsert_1.upsertConfigurationRoute(libs));
    libs.framework.registerRoute(assignable_1.createAssignableTagsRoute(libs));
    libs.framework.registerRoute(events_1.beatEventsRoute(libs));
};

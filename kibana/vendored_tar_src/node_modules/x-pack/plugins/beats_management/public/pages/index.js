"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const details_1 = require("./beat/details");
const index_1 = require("./beat/index");
const tags_1 = require("./beat/tags");
const enforce_security_1 = require("./error/enforce_security");
const invalid_license_1 = require("./error/invalid_license");
const no_access_1 = require("./error/no_access");
const configuration_tags_1 = require("./overview/configuration_tags");
const enrolled_beats_1 = require("./overview/enrolled_beats");
const index_2 = require("./overview/index");
const create_1 = require("./tag/create");
const edit_1 = require("./tag/edit");
const beat_1 = require("./walkthrough/initial/beat");
const finish_1 = require("./walkthrough/initial/finish");
const index_3 = require("./walkthrough/initial/index");
const tag_1 = require("./walkthrough/initial/tag");
exports.routeMap = [
    { path: '/tag/create/:tagid?', component: create_1.TagCreatePage },
    { path: '/tag/edit/:tagid?', component: edit_1.TagEditPage },
    {
        path: '/beat/:beatId',
        component: index_1.BeatDetailsPage,
        routes: [
            { path: '/beat/:beatId/details', component: details_1.BeatDetailPage },
            { path: '/beat/:beatId/tags', component: tags_1.BeatTagsPage },
        ],
    },
    { path: '/error/enforce_security', component: enforce_security_1.EnforceSecurityPage },
    { path: '/error/invalid_license', component: invalid_license_1.InvalidLicensePage },
    { path: '/error/no_access', component: no_access_1.NoAccessPage },
    {
        path: '/overview',
        component: index_2.MainPage,
        routes: [
            { path: '/overview/configuration_tags', component: configuration_tags_1.TagsPage },
            { path: '/overview/enrolled_beats', component: enrolled_beats_1.BeatsPage },
        ],
    },
    {
        path: '/walkthrough/initial',
        component: index_3.InitialWalkthroughPage,
        routes: [
            { path: '/walkthrough/initial/beat', component: beat_1.BeatsInitialEnrollmentPage },
            { path: '/walkthrough/initial/finish', component: finish_1.FinishWalkthroughPage },
            { path: '/walkthrough/initial/tag', component: tag_1.InitialTagPage },
        ],
    },
];

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const i18n_1 = require("@kbn/i18n");
const feature_catalogue_1 = require("ui/registry/feature_catalogue");
const constants_1 = require("./lib/constants");
feature_catalogue_1.FeatureCatalogueRegistryProvider.register(() => {
    return {
        id: 'spaces',
        title: i18n_1.i18n.translate('xpack.spaces.spacesTitle', {
            defaultMessage: 'Spaces',
        }),
        description: constants_1.getSpacesFeatureDescription(),
        icon: 'spacesApp',
        path: '/app/kibana#/management/spaces/list',
        showOnHomePage: true,
        category: feature_catalogue_1.FeatureCatalogueCategory.ADMIN,
    };
});

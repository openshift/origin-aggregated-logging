"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const i18n_1 = require("@kbn/i18n");
const feature_catalogue_1 = require("ui/registry/feature_catalogue");
feature_catalogue_1.FeatureCatalogueRegistryProvider.register(() => ({
    id: 'uptime',
    title: i18n_1.i18n.translate('xpack.uptime.uptimeFeatureCatalogueTitle', { defaultMessage: 'Uptime' }),
    description: i18n_1.i18n.translate('xpack.uptime.featureCatalogueDescription', {
        defaultMessage: 'Perform endpoint health checks and uptime monitoring.',
    }),
    icon: 'uptimeApp',
    path: `uptime#/`,
    showOnHomePage: true,
    category: feature_catalogue_1.FeatureCatalogueCategory.DATA,
}));

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const i18n_1 = require("@kbn/i18n");
const chrome_1 = tslib_1.__importDefault(require("ui/chrome"));
let spacesFeatureDescription;
exports.getSpacesFeatureDescription = () => {
    if (!spacesFeatureDescription) {
        spacesFeatureDescription = i18n_1.i18n.translate('xpack.spaces.featureDescription', {
            defaultMessage: 'Organize your dashboards and other saved objects into meaningful categories.',
        });
    }
    return spacesFeatureDescription;
};
exports.MANAGE_SPACES_URL = chrome_1.default.addBasePath(`/app/kibana#/management/spaces/list`);

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const reselect_1 = require("reselect");
const license_1 = require("x-pack/plugins/apm/public/store/reactReduxRequest/license");
exports.selectIsMLAvailable = reselect_1.createSelector([license_1.getLicense], license => license.data &&
    license.data.features &&
    license.data.features.ml &&
    license.data.features.ml.is_available);

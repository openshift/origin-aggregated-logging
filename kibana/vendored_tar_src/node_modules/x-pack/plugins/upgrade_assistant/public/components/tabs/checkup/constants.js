"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const lodash_1 = require("lodash");
exports.LEVEL_MAP = {
    warning: 0,
    critical: 1,
};
exports.REVERSE_LEVEL_MAP = lodash_1.invert(exports.LEVEL_MAP);
exports.COLOR_MAP = {
    warning: 'default',
    critical: 'danger',
};

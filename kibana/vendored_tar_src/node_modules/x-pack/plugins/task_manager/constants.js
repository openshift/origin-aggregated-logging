"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const package_json_1 = tslib_1.__importDefault(require("../../package.json"));
const get_template_version_1 = require("./lib/get_template_version");
exports.TASK_MANAGER_API_VERSION = 1;
exports.TASK_MANAGER_TEMPLATE_VERSION = get_template_version_1.getTemplateVersion(package_json_1.default.version);

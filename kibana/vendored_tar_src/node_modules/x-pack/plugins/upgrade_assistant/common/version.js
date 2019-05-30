"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const semver_1 = require("semver");
const package_json_1 = tslib_1.__importDefault(require("../../../package.json"));
exports.CURRENT_VERSION = new semver_1.SemVer(package_json_1.default.version);
exports.CURRENT_MAJOR_VERSION = exports.CURRENT_VERSION.major;
exports.NEXT_MAJOR_VERSION = exports.CURRENT_VERSION.major + 1;
exports.PREV_MAJOR_VERSION = exports.CURRENT_VERSION.major - 1;

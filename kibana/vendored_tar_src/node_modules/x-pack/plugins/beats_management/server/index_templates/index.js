"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const beats_template_json_1 = tslib_1.__importDefault(require("./beats_template.json"));
exports.beatsIndexTemplate = beats_template_json_1.default;
const events_template_json_1 = tslib_1.__importDefault(require("./events_template.json"));
exports.eventsIndexTemplate = events_template_json_1.default;

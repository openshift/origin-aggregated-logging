"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
var action_schema_1 = require("./action_schema");
exports.beatsListActions = action_schema_1.beatsListActions;
exports.tagConfigActions = action_schema_1.tagConfigActions;
var table_1 = require("./table");
exports.AssignmentActionType = table_1.AssignmentActionType;
exports.Table = table_1.Table;
var table_type_configs_1 = require("./table_type_configs");
exports.BeatDetailTagsTable = table_type_configs_1.BeatDetailTagsTable;
exports.BeatsTableType = table_type_configs_1.BeatsTableType;
exports.TagsTableType = table_type_configs_1.TagsTableType;

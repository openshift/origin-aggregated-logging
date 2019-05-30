"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
var space_identifier_utils_1 = require("./space_identifier_utils");
exports.toSpaceIdentifier = space_identifier_utils_1.toSpaceIdentifier;
exports.isValidSpaceIdentifier = space_identifier_utils_1.isValidSpaceIdentifier;
var validate_space_1 = require("./validate_space");
exports.SpaceValidator = validate_space_1.SpaceValidator;

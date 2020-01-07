"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
var is_reserved_space_1 = require("./is_reserved_space");
exports.isReservedSpace = is_reserved_space_1.isReservedSpace;
var constants_1 = require("./constants");
exports.MAX_SPACE_INITIALS = constants_1.MAX_SPACE_INITIALS;
var space_attributes_1 = require("./space_attributes");
exports.getSpaceInitials = space_attributes_1.getSpaceInitials;
exports.getSpaceColor = space_attributes_1.getSpaceColor;

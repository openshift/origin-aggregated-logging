"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
function isWaffleMapGroupWithNodes(subject) {
    return subject && subject.nodes != null && Array.isArray(subject.nodes);
}
exports.isWaffleMapGroupWithNodes = isWaffleMapGroupWithNodes;
function isWaffleMapGroupWithGroups(subject) {
    return subject && subject.groups != null && Array.isArray(subject.groups);
}
exports.isWaffleMapGroupWithGroups = isWaffleMapGroupWithGroups;

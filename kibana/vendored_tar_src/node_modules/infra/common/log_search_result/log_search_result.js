"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const d3_array_1 = require("d3-array");
const time_1 = require("../time");
exports.getSearchResultKey = (result) => ({
    gid: result.gid,
    tiebreaker: result.fields.tiebreaker,
    time: result.fields.time,
});
const searchResultTimeBisector = d3_array_1.bisector(time_1.compareToTimeKey(exports.getSearchResultKey));
exports.getSearchResultIndexBeforeTime = searchResultTimeBisector.left;
exports.getSearchResultIndexAfterTime = searchResultTimeBisector.right;

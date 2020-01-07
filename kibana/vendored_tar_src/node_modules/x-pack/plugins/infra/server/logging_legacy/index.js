"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adjacent_search_results_1 = require("./adjacent_search_results");
const contained_search_results_1 = require("./contained_search_results");
const search_summary_1 = require("./search_summary");
exports.initLegacyLoggingRoutes = (framework) => {
    adjacent_search_results_1.initAdjacentSearchResultsRoutes(framework);
    contained_search_results_1.initContainedSearchResultsRoutes(framework);
    search_summary_1.initSearchSummaryRoutes(framework);
};

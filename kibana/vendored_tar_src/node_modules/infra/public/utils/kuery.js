"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const es_query_1 = require("@kbn/es-query");
exports.convertKueryToElasticSearchQuery = (kueryExpression, indexPattern) => {
    try {
        return kueryExpression
            ? JSON.stringify(es_query_1.toElasticsearchQuery(es_query_1.fromKueryExpression(kueryExpression), indexPattern))
            : '';
    }
    catch (err) {
        return '';
    }
};

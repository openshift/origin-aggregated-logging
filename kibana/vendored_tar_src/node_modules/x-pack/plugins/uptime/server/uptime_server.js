"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const graphql_tools_1 = require("graphql-tools");
const graphql_1 = require("./graphql");
const rest_api_1 = require("./rest_api");
exports.initUptimeServer = (libs) => {
    rest_api_1.restApiRoutes.forEach(route => libs.framework.registerRoute(rest_api_1.createRouteWithAuth(libs, route)));
    const graphQLSchema = graphql_tools_1.makeExecutableSchema({
        resolvers: graphql_1.resolvers.map(createResolversFn => createResolversFn(libs)),
        typeDefs: graphql_1.typeDefs,
    });
    libs.framework.registerGraphQLEndpoint(graphql_1.DEFAULT_GRAPHQL_PATH, graphQLSchema);
};

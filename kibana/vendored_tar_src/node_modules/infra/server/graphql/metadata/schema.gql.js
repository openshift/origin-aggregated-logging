"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const graphql_tag_1 = tslib_1.__importDefault(require("graphql-tag"));
exports.metadataSchema = graphql_tag_1.default `
  "One metadata entry for a node."
  type InfraNodeMetadata {
    id: ID!
    name: String!
    features: [InfraNodeFeature!]!
  }

  type InfraNodeFeature {
    name: String!
    source: String!
  }

  extend type InfraSource {
    "A hierarchy of metadata entries by node"
    metadataByNode(nodeId: String!, nodeType: InfraNodeType!): InfraNodeMetadata!
  }
`;

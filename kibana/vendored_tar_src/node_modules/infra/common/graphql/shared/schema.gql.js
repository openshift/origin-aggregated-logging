"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const graphql_tag_1 = tslib_1.__importDefault(require("graphql-tag"));
exports.sharedSchema = graphql_tag_1.default `
  "A representation of the log entry's position in the event stream"
  type InfraTimeKey {
    "The timestamp of the event that the log entry corresponds to"
    time: Float!
    "The tiebreaker that disambiguates events with the same timestamp"
    tiebreaker: Float!
  }

  input InfraTimeKeyInput {
    time: Float!
    tiebreaker: Float!
  }

  enum InfraIndexType {
    ANY
    LOGS
    METRICS
  }

  enum InfraNodeType {
    pod
    container
    host
  }
`;

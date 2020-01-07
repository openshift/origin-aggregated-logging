"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const container_1 = require("./container");
const host_1 = require("./host");
const pod_1 = require("./pod");
exports.layoutCreators = {
    host: host_1.hostLayoutCreator,
    pod: pod_1.podLayoutCreator,
    container: container_1.containerLayoutCreator,
};

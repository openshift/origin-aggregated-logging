"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const kibana_1 = require("./lib/compose/kibana");
const management_server_1 = require("./management_server");
exports.initServerWithKibana = (hapiServer) => {
    const libs = kibana_1.compose(hapiServer);
    management_server_1.initManagementServer(libs);
};

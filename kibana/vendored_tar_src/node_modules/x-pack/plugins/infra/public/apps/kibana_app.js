"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
require("uiExports/autocompleteProviders");
const kibana_compose_1 = require("../lib/compose/kibana_compose");
const start_app_1 = require("./start_app");
start_app_1.startApp(kibana_compose_1.compose());

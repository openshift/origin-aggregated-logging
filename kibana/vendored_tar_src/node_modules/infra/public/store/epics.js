"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const redux_observable_1 = require("redux-observable");
const local_1 = require("./local");
const remote_1 = require("./remote");
exports.createRootEpic = () => redux_observable_1.combineEpics(local_1.createLocalEpic(), remote_1.createRemoteEpic());

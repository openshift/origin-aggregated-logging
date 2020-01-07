"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const redux_1 = require("redux");
const local_1 = require("./local");
const remote_1 = require("./remote");
exports.initialState = {
    local: local_1.initialLocalState,
    remote: remote_1.initialRemoteState,
};
exports.reducer = redux_1.combineReducers({
    local: local_1.localReducer,
    remote: remote_1.remoteReducer,
});

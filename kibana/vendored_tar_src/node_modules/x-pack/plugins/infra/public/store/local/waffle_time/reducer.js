"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const redux_1 = require("redux");
const dist_1 = require("typescript-fsa-reducers/dist");
const actions_1 = require("./actions");
exports.initialWaffleTimeState = {
    currentTime: Date.now(),
    updatePolicy: {
        policy: 'manual',
    },
};
const currentTimeReducer = dist_1.reducerWithInitialState(exports.initialWaffleTimeState.currentTime).case(actions_1.jumpToTime, (currentTime, targetTime) => targetTime);
const updatePolicyReducer = dist_1.reducerWithInitialState(exports.initialWaffleTimeState.updatePolicy)
    .case(actions_1.startAutoReload, () => ({
    policy: 'interval',
    interval: 5000,
}))
    .case(actions_1.stopAutoReload, () => ({
    policy: 'manual',
}));
exports.waffleTimeReducer = redux_1.combineReducers({
    currentTime: currentTimeReducer,
    updatePolicy: updatePolicyReducer,
});

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const reselect_1 = require("reselect");
exports.selectCurrentTime = (state) => state.currentTime;
exports.selectIsAutoReloading = (state) => state.updatePolicy.policy === 'interval';
exports.selectTimeUpdatePolicyInterval = (state) => state.updatePolicy.policy === 'interval' ? state.updatePolicy.interval : null;
exports.selectCurrentTimeRange = reselect_1.createSelector(exports.selectCurrentTime, currentTime => ({
    from: currentTime - 1000 * 60 * 5,
    interval: '1m',
    to: currentTime,
}));

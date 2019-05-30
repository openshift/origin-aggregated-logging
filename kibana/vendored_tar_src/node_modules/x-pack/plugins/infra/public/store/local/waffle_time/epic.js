"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const rxjs_1 = require("rxjs");
const operators_1 = require("rxjs/operators");
const actions_1 = require("./actions");
exports.createWaffleTimeEpic = () => (action$, state$, { selectWaffleTimeUpdatePolicyInterval }) => {
    const updateInterval$ = state$.pipe(operators_1.map(selectWaffleTimeUpdatePolicyInterval), operators_1.filter(isNotNull));
    return action$.pipe(operators_1.filter(actions_1.startAutoReload.match), operators_1.withLatestFrom(updateInterval$), operators_1.exhaustMap(([action, updateInterval]) => rxjs_1.timer(0, updateInterval).pipe(operators_1.map(() => actions_1.jumpToTime(Date.now())), operators_1.takeUntil(action$.pipe(operators_1.filter(actions_1.stopAutoReload.match))))));
};
const isNotNull = (value) => value !== null;

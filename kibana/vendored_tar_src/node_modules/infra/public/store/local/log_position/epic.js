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
exports.createLogPositionEpic = () => action$ => action$.pipe(operators_1.filter(actions_1.startAutoReload.match), operators_1.exhaustMap(({ payload }) => rxjs_1.timer(0, payload).pipe(operators_1.map(() => actions_1.jumpToTargetPositionTime(Date.now())), operators_1.takeUntil(action$.pipe(operators_1.filter(actions_1.stopAutoReload.match))))));

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
var loading_state_1 = require("./loading_state");
exports.initialLoadingState = loading_state_1.initialLoadingState;
var loading_policy_1 = require("./loading_policy");
exports.isManualLoadingPolicy = loading_policy_1.isManualLoadingPolicy;
exports.isIntervalLoadingPolicy = loading_policy_1.isIntervalLoadingPolicy;
var loading_progress_1 = require("./loading_progress");
exports.createRunningProgressReducer = loading_progress_1.createRunningProgressReducer;
exports.createIdleProgressReducer = loading_progress_1.createIdleProgressReducer;
exports.isIdleLoadingProgress = loading_progress_1.isIdleLoadingProgress;
exports.isRunningLoadingProgress = loading_progress_1.isRunningLoadingProgress;
var loading_result_1 = require("./loading_result");
exports.createFailureResult = loading_result_1.createFailureResult;
exports.createFailureResultReducer = loading_result_1.createFailureResultReducer;
exports.createSuccessResult = loading_result_1.createSuccessResult;
exports.createSuccessResultReducer = loading_result_1.createSuccessResultReducer;
exports.getTimeOrDefault = loading_result_1.getTimeOrDefault;
exports.isExhaustedLoadingResult = loading_result_1.isExhaustedLoadingResult;
exports.isFailureLoadingResult = loading_result_1.isFailureLoadingResult;
exports.isSuccessLoadingResult = loading_result_1.isSuccessLoadingResult;
exports.isUninitializedLoadingResult = loading_result_1.isUninitializedLoadingResult;

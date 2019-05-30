"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.isIdleLoadingProgress = (loadingProgress) => loadingProgress.progress === 'idle';
exports.isRunningLoadingProgress = (loadingProgress) => loadingProgress.progress === 'running';
exports.createIdleProgressReducer = () => (state) => ({
    progress: 'idle',
});
exports.createRunningProgressReducer = () => (state, parameters) => ({
    parameters,
    progress: 'running',
    time: Date.now(),
});

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const axios_1 = tslib_1.__importDefault(require("axios"));
const chrome_1 = tslib_1.__importDefault(require("ui/chrome"));
const rxjs_1 = require("rxjs");
const types_1 = require("../../../../../../common/types");
const types_2 = require("../../../../types");
const POLL_INTERVAL = 1000;
const XSRF = chrome_1.default.getXsrfToken();
exports.APIClient = axios_1.default.create({
    headers: {
        Accept: 'application/json',
        credentials: 'same-origin',
        'Content-Type': 'application/json',
        'kbn-version': XSRF,
        'kbn-xsrf': XSRF,
    },
});
/**
 * Service used by the frontend to start reindexing and get updates on the state of a reindex
 * operation. Exposes an Observable that can be used to subscribe to state updates.
 */
class ReindexPollingService {
    constructor(indexName) {
        this.indexName = indexName;
        this.updateStatus = async () => {
            // Prevent two loops from being started.
            this.stopPolling();
            try {
                const { data } = await exports.APIClient.get(chrome_1.default.addBasePath(`/api/upgrade_assistant/reindex/${this.indexName}`));
                this.updateWithResponse(data);
                // Only keep polling if it exists and is in progress.
                if (data.reindexOp && data.reindexOp.status === types_1.ReindexStatus.inProgress) {
                    this.pollTimeout = setTimeout(this.updateStatus, POLL_INTERVAL);
                }
            }
            catch (e) {
                this.status$.next({
                    ...this.status$.value,
                    status: types_1.ReindexStatus.failed,
                });
            }
        };
        this.stopPolling = () => {
            if (this.pollTimeout) {
                clearTimeout(this.pollTimeout);
            }
        };
        this.startReindex = async () => {
            try {
                // Optimistically assume it will start, reset other state.
                const currentValue = this.status$.value;
                this.status$.next({
                    ...currentValue,
                    // Only reset last completed step if we aren't currently paused
                    lastCompletedStep: currentValue.status === types_1.ReindexStatus.paused ? currentValue.lastCompletedStep : undefined,
                    status: types_1.ReindexStatus.inProgress,
                    reindexTaskPercComplete: null,
                    errorMessage: null,
                    cancelLoadingState: undefined,
                });
                const { data } = await exports.APIClient.post(chrome_1.default.addBasePath(`/api/upgrade_assistant/reindex/${this.indexName}`));
                this.updateWithResponse({ reindexOp: data });
                this.updateStatus();
            }
            catch (e) {
                this.status$.next({ ...this.status$.value, status: types_1.ReindexStatus.failed });
            }
        };
        this.cancelReindex = async () => {
            try {
                this.status$.next({
                    ...this.status$.value,
                    cancelLoadingState: types_2.LoadingState.Loading,
                });
                await exports.APIClient.post(chrome_1.default.addBasePath(`/api/upgrade_assistant/reindex/${this.indexName}/cancel`));
            }
            catch (e) {
                this.status$.next({
                    ...this.status$.value,
                    cancelLoadingState: types_2.LoadingState.Error,
                });
            }
        };
        this.updateWithResponse = ({ reindexOp, warnings, hasRequiredPrivileges, indexGroup, }) => {
            const currentValue = this.status$.value;
            // Next value should always include the entire state, not just what changes.
            // We make a shallow copy as a starting new state.
            const nextValue = {
                ...currentValue,
                // If we're getting any updates, set to success.
                loadingState: types_2.LoadingState.Success,
            };
            if (warnings) {
                nextValue.reindexWarnings = warnings;
            }
            if (hasRequiredPrivileges !== undefined) {
                nextValue.hasRequiredPrivileges = hasRequiredPrivileges;
            }
            if (indexGroup) {
                nextValue.indexGroup = indexGroup;
            }
            if (reindexOp) {
                // Prevent the UI flickering back to inProgres after cancelling.
                nextValue.lastCompletedStep = reindexOp.lastCompletedStep;
                nextValue.status = reindexOp.status;
                nextValue.reindexTaskPercComplete = reindexOp.reindexTaskPercComplete;
                nextValue.errorMessage = reindexOp.errorMessage;
                if (reindexOp.status === types_1.ReindexStatus.cancelled) {
                    nextValue.cancelLoadingState = types_2.LoadingState.Success;
                }
            }
            this.status$.next(nextValue);
        };
        this.status$ = new rxjs_1.BehaviorSubject({
            loadingState: types_2.LoadingState.Loading,
            errorMessage: null,
            reindexTaskPercComplete: null,
        });
    }
}
exports.ReindexPollingService = ReindexPollingService;

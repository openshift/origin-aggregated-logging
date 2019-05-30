"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importDefault(require("react"));
const eui_1 = require("@elastic/eui");
const react_2 = require("@kbn/i18n/react");
const types_1 = require("../../../../../../../common/types");
const types_2 = require("../../../../../types");
const step_progress_1 = require("./step_progress");
const ErrorCallout = ({ errorMessage, }) => (react_1.default.createElement(eui_1.EuiCallOut, { color: "danger", title: "There was an error" },
    react_1.default.createElement(eui_1.EuiText, null,
        react_1.default.createElement("p", null, errorMessage))));
const PausedCallout = () => (react_1.default.createElement(eui_1.EuiCallOut, { color: "warning", title: "This step was paused due to a Kibana restart. Click 'Resume' below to continue." }));
const ReindexProgressBar = ({ reindexState: { lastCompletedStep, status, reindexTaskPercComplete, cancelLoadingState }, cancelReindex, }) => {
    const progressBar = reindexTaskPercComplete ? (react_1.default.createElement(eui_1.EuiProgress, { size: "s", value: reindexTaskPercComplete, max: 1 })) : (react_1.default.createElement(eui_1.EuiProgress, { size: "s" }));
    let cancelText;
    switch (cancelLoadingState) {
        case types_2.LoadingState.Loading:
            cancelText = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.flyout.checklistStep.reindexingChecklist.cancelButton.cancellingLabel", defaultMessage: "Cancelling\u2026" }));
            break;
        case types_2.LoadingState.Success:
            cancelText = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.flyout.checklistStep.reindexingChecklist.cancelButton.cancelledLabel", defaultMessage: "Cancelled" }));
            break;
        case types_2.LoadingState.Error:
            cancelText = 'Could not cancel';
            cancelText = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.flyout.checklistStep.reindexingChecklist.cancelButton.errorLabel", defaultMessage: "Could not cancel" }));
            break;
        default:
            cancelText = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.flyout.checklistStep.reindexingChecklist.cancelButton.cancelLabel", defaultMessage: "Cancel" }));
    }
    return (react_1.default.createElement(eui_1.EuiFlexGroup, { alignItems: 'center' },
        react_1.default.createElement(eui_1.EuiFlexItem, null, progressBar),
        react_1.default.createElement(eui_1.EuiFlexItem, { grow: false },
            react_1.default.createElement(eui_1.EuiButtonEmpty, { onClick: cancelReindex, disabled: cancelLoadingState === types_2.LoadingState.Loading ||
                    status !== types_1.ReindexStatus.inProgress ||
                    lastCompletedStep !== types_1.ReindexStep.reindexStarted, isLoading: cancelLoadingState === types_2.LoadingState.Loading }, cancelText))));
};
const orderedSteps = Object.values(types_1.ReindexStep).sort();
/**
 * Displays a list of steps in the reindex operation, the current status, a progress bar,
 * and any error messages that are encountered.
 */
exports.ReindexProgress = props => {
    const { errorMessage, indexGroup, lastCompletedStep = -1, status } = props.reindexState;
    const stepDetails = (thisStep) => {
        const previousStep = orderedSteps[orderedSteps.indexOf(thisStep) - 1];
        if (status === types_1.ReindexStatus.failed && lastCompletedStep === previousStep) {
            return {
                status: 'failed',
                children: react_1.default.createElement(ErrorCallout, Object.assign({}, { errorMessage })),
            };
        }
        else if (status === types_1.ReindexStatus.paused && lastCompletedStep === previousStep) {
            return {
                status: 'paused',
                children: react_1.default.createElement(PausedCallout, null),
            };
        }
        else if (status === types_1.ReindexStatus.cancelled && lastCompletedStep === previousStep) {
            return {
                status: 'cancelled',
            };
        }
        else if (status === undefined || lastCompletedStep < previousStep) {
            return {
                status: 'incomplete',
            };
        }
        else if (lastCompletedStep === previousStep) {
            return {
                status: 'inProgress',
            };
        }
        else {
            return {
                status: 'complete',
            };
        }
    };
    // The reindexing step is special because it combines the starting and complete statuses into a single UI
    // with a progress bar.
    const reindexingDocsStep = {
        title: (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.flyout.checklistStep.reindexingChecklist.reindexingDocumentsStepTitle", defaultMessage: "Reindexing documents" })),
    };
    if (status === types_1.ReindexStatus.failed &&
        (lastCompletedStep === types_1.ReindexStep.newIndexCreated ||
            lastCompletedStep === types_1.ReindexStep.reindexStarted)) {
        reindexingDocsStep.status = 'failed';
        reindexingDocsStep.children = react_1.default.createElement(ErrorCallout, Object.assign({}, { errorMessage }));
    }
    else if (status === types_1.ReindexStatus.paused &&
        (lastCompletedStep === types_1.ReindexStep.newIndexCreated ||
            lastCompletedStep === types_1.ReindexStep.reindexStarted)) {
        reindexingDocsStep.status = 'paused';
        reindexingDocsStep.children = react_1.default.createElement(PausedCallout, null);
    }
    else if (status === types_1.ReindexStatus.cancelled &&
        (lastCompletedStep === types_1.ReindexStep.newIndexCreated ||
            lastCompletedStep === types_1.ReindexStep.reindexStarted)) {
        reindexingDocsStep.status = 'cancelled';
    }
    else if (status === undefined || lastCompletedStep < types_1.ReindexStep.newIndexCreated) {
        reindexingDocsStep.status = 'incomplete';
    }
    else if (lastCompletedStep === types_1.ReindexStep.newIndexCreated ||
        lastCompletedStep === types_1.ReindexStep.reindexStarted) {
        reindexingDocsStep.status = 'inProgress';
        reindexingDocsStep.children = react_1.default.createElement(ReindexProgressBar, Object.assign({}, props));
    }
    else {
        reindexingDocsStep.status = 'complete';
    }
    const steps = [
        {
            title: (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.flyout.checklistStep.reindexingChecklist.readonlyStepTitle", defaultMessage: "Setting old index to read-only" })),
            ...stepDetails(types_1.ReindexStep.readonly),
        },
        {
            title: (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.flyout.checklistStep.reindexingChecklist.createIndexStepTitle", defaultMessage: "Creating new index" })),
            ...stepDetails(types_1.ReindexStep.newIndexCreated),
        },
        reindexingDocsStep,
        {
            title: (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.flyout.checklistStep.reindexingChecklist.aliasSwapStepTitle", defaultMessage: "Swapping original index with alias" })),
            ...stepDetails(types_1.ReindexStep.aliasCreated),
        },
    ];
    // If this index is part of an index group, add the approriate group services steps.
    if (indexGroup === types_1.IndexGroup.ml) {
        steps.unshift({
            title: (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.flyout.checklistStep.reindexingChecklist.pauseMlStepTitle", defaultMessage: "Pausing Machine Learning jobs" })),
            ...stepDetails(types_1.ReindexStep.indexGroupServicesStopped),
        });
        steps.push({
            title: (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.flyout.checklistStep.reindexingChecklist.resumeMlStepTitle", defaultMessage: "Resuming Machine Learning jobs" })),
            ...stepDetails(types_1.ReindexStep.indexGroupServicesStarted),
        });
    }
    else if (indexGroup === types_1.IndexGroup.watcher) {
        steps.unshift({
            title: (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.flyout.checklistStep.reindexingChecklist.stopWatcherStepTitle", defaultMessage: "Stopping Watcher" })),
            ...stepDetails(types_1.ReindexStep.indexGroupServicesStopped),
        });
        steps.push({
            title: (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.flyout.checklistStep.reindexingChecklist.resumeWatcherStepTitle", defaultMessage: "Resuming Watcher" })),
            ...stepDetails(types_1.ReindexStep.indexGroupServicesStarted),
        });
    }
    return react_1.default.createElement(step_progress_1.StepProgress, { steps: steps });
};

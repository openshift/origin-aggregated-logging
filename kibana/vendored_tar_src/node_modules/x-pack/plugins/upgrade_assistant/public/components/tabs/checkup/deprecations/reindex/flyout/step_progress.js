"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const classnames_1 = tslib_1.__importDefault(require("classnames"));
const react_1 = tslib_1.__importStar(require("react"));
const eui_1 = require("@elastic/eui");
const StepStatus = ({ status, idx }) => {
    if (status === 'incomplete') {
        return react_1.default.createElement("span", { className: "upgStepProgress__status" },
            idx + 1,
            ".");
    }
    else if (status === 'inProgress') {
        return react_1.default.createElement(eui_1.EuiLoadingSpinner, { size: "m", className: "upgStepProgress__status" });
    }
    else if (status === 'complete') {
        return (react_1.default.createElement("span", { className: "upgStepProgress__status upgStepProgress__status--circle upgStepProgress__status--circle-complete" },
            react_1.default.createElement(eui_1.EuiIcon, { type: "check", size: "s" })));
    }
    else if (status === 'paused') {
        return (react_1.default.createElement("span", { className: "upgStepProgress__status upgStepProgress__status--circle upgStepProgress__status--circle-paused" },
            react_1.default.createElement(eui_1.EuiIcon, { type: "pause", size: "s" })));
    }
    else if (status === 'cancelled') {
        return (react_1.default.createElement("span", { className: "upgStepProgress__status upgStepProgress__status--circle upgStepProgress__status--circle-cancelled" },
            react_1.default.createElement(eui_1.EuiIcon, { type: "cross", size: "s" })));
    }
    else if (status === 'failed') {
        return (react_1.default.createElement("span", { className: "upgStepProgress__status upgStepProgress__status--circle upgStepProgress__status--circle-failed" },
            react_1.default.createElement(eui_1.EuiIcon, { type: "cross", size: "s" })));
    }
    throw new Error(`Unsupported status: ${status}`);
};
const Step = ({ title, status, children, idx, }) => {
    const titleClassName = classnames_1.default('upgStepProgress__title', {
        'upgStepProgress__title--currentStep': status === 'inProgress' ||
            status === 'paused' ||
            status === 'failed' ||
            status === 'cancelled',
    });
    return (react_1.default.createElement(react_1.Fragment, null,
        react_1.default.createElement("div", { className: "upgStepProgress__step" },
            react_1.default.createElement(StepStatus, { status: status, idx: idx }),
            react_1.default.createElement("p", { className: titleClassName }, title)),
        children && react_1.default.createElement("div", { className: "upgStepProgress__content" }, children)));
};
/**
 * A generic component that displays a series of automated steps and the system's progress.
 */
exports.StepProgress = ({ steps }) => {
    return (react_1.default.createElement("div", { className: "upgStepProgress__container" }, steps.map((step, idx) => (react_1.default.createElement(Step, Object.assign({ key: idx }, step, { idx: idx }))))));
};

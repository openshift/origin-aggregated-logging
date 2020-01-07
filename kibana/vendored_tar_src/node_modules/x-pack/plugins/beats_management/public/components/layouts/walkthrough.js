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
exports.WalkthroughLayout = ({ walkthroughSteps, title, activePath, goTo, children, }) => {
    const indexOfCurrent = walkthroughSteps.findIndex(step => activePath === step.id);
    return (react_1.default.createElement(eui_1.EuiPageContent, null,
        react_1.default.createElement(eui_1.EuiTitle, null,
            react_1.default.createElement("h1", { style: { textAlign: 'center' } }, title)),
        react_1.default.createElement("br", null),
        react_1.default.createElement("br", null),
        react_1.default.createElement(eui_1.EuiStepsHorizontal, { steps: walkthroughSteps.map((step, i) => ({
                title: step.name,
                isComplete: i <= indexOfCurrent,
                onClick: () => goTo(step.id),
            })) }),
        react_1.default.createElement("br", null),
        react_1.default.createElement("br", null),
        react_1.default.createElement(eui_1.EuiPageContentBody, null, children)));
};

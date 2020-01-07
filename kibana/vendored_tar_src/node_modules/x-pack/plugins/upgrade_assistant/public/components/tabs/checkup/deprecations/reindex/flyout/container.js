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
const checklist_step_1 = require("./checklist_step");
const warnings_step_1 = require("./warnings_step");
var ReindexFlyoutStep;
(function (ReindexFlyoutStep) {
    ReindexFlyoutStep[ReindexFlyoutStep["reindexWarnings"] = 0] = "reindexWarnings";
    ReindexFlyoutStep[ReindexFlyoutStep["checklist"] = 1] = "checklist";
})(ReindexFlyoutStep || (ReindexFlyoutStep = {}));
/**
 * Wrapper for the contents of the flyout that manages which step of the flyout to show.
 */
class ReindexFlyout extends react_1.default.Component {
    constructor(props) {
        super(props);
        this.advanceNextStep = () => {
            this.setState({ currentFlyoutStep: ReindexFlyoutStep.checklist });
        };
        const { status, reindexWarnings } = props.reindexState;
        this.state = {
            // If there are any warnings and we haven't started reindexing, show the warnings step first.
            currentFlyoutStep: reindexWarnings && reindexWarnings.length > 0 && status === undefined
                ? ReindexFlyoutStep.reindexWarnings
                : ReindexFlyoutStep.checklist,
        };
    }
    render() {
        const { closeFlyout, indexName, reindexState, startReindex, cancelReindex } = this.props;
        const { currentFlyoutStep } = this.state;
        let flyoutContents;
        switch (currentFlyoutStep) {
            case ReindexFlyoutStep.reindexWarnings:
                flyoutContents = (react_1.default.createElement(warnings_step_1.WarningsFlyoutStep, { closeFlyout: closeFlyout, warnings: reindexState.reindexWarnings, advanceNextStep: this.advanceNextStep }));
                break;
            case ReindexFlyoutStep.checklist:
                flyoutContents = (react_1.default.createElement(checklist_step_1.ChecklistFlyoutStep, { closeFlyout: closeFlyout, reindexState: reindexState, startReindex: startReindex, cancelReindex: cancelReindex }));
                break;
            default:
                throw new Error(`Invalid flyout step: ${currentFlyoutStep}`);
        }
        return (react_1.default.createElement(eui_1.EuiPortal, null,
            react_1.default.createElement(eui_1.EuiFlyout, { onClose: closeFlyout, "aria-labelledby": "Reindex", ownFocus: true, size: "m", maxWidth: true },
                react_1.default.createElement(eui_1.EuiFlyoutHeader, { hasBorder: true },
                    react_1.default.createElement(eui_1.EuiTitle, { size: "s" },
                        react_1.default.createElement("h2", null,
                            react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.flyout.flyoutHeader", defaultMessage: "Reindex {indexName}", values: { indexName } })))),
                flyoutContents)));
    }
}
exports.ReindexFlyout = ReindexFlyout;

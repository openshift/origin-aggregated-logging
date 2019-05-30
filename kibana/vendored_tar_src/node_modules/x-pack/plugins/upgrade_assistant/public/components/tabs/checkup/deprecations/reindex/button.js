"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const lodash_1 = require("lodash");
const react_1 = tslib_1.__importStar(require("react"));
const eui_1 = require("@elastic/eui");
const react_2 = require("@kbn/i18n/react");
const kfetch_1 = require("ui/kfetch");
const types_1 = require("../../../../../../common/types");
const types_2 = require("../../../../types");
const flyout_1 = require("./flyout");
const polling_service_1 = require("./polling_service");
/**
 * Displays a button that will display a flyout when clicked with the reindexing status for
 * the given `indexName`.
 */
class ReindexButton extends react_1.default.Component {
    constructor(props) {
        super(props);
        this.startReindex = async () => {
            if (!this.state.reindexState.status) {
                // if status didn't exist we are starting a reindex action
                this.sendUIReindexTelemetryInfo('start');
            }
            await this.service.startReindex();
        };
        this.cancelReindex = async () => {
            this.sendUIReindexTelemetryInfo('stop');
            await this.service.cancelReindex();
        };
        this.showFlyout = () => {
            this.sendUIReindexTelemetryInfo('open');
            this.setState({ flyoutVisible: true });
        };
        this.closeFlyout = () => {
            this.sendUIReindexTelemetryInfo('close');
            this.setState({ flyoutVisible: false });
        };
        this.service = this.newService();
        this.state = {
            flyoutVisible: false,
            reindexState: this.service.status$.value,
        };
    }
    async componentDidMount() {
        this.subscribeToUpdates();
    }
    async componentWillUnmount() {
        this.unsubscribeToUpdates();
    }
    componentDidUpdate(prevProps) {
        if (prevProps.indexName !== this.props.indexName) {
            this.unsubscribeToUpdates();
            this.service = this.newService();
            this.subscribeToUpdates();
        }
    }
    render() {
        const { indexName } = this.props;
        const { flyoutVisible, reindexState } = this.state;
        const buttonProps = { size: 's', onClick: this.showFlyout };
        let buttonContent = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.reindexButton.reindexLabel", defaultMessage: "Reindex" }));
        if (reindexState.loadingState === types_2.LoadingState.Loading) {
            buttonProps.disabled = true;
            buttonContent = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.reindexButton.loadingLabel", defaultMessage: "Loading\u2026" }));
        }
        else {
            switch (reindexState.status) {
                case types_1.ReindexStatus.inProgress:
                    buttonContent = (react_1.default.createElement("span", null,
                        react_1.default.createElement(eui_1.EuiLoadingSpinner, { className: "upgReindexButton__spinner", size: "m" }),
                        " Reindexing\u2026"));
                    break;
                case types_1.ReindexStatus.completed:
                    buttonProps.color = 'secondary';
                    buttonProps.iconSide = 'left';
                    buttonProps.iconType = 'check';
                    buttonContent = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.reindexButton.doneLabel", defaultMessage: "Done" }));
                    break;
                case types_1.ReindexStatus.failed:
                    buttonProps.color = 'danger';
                    buttonProps.iconSide = 'left';
                    buttonProps.iconType = 'cross';
                    buttonContent = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.reindexButton.failedLabel", defaultMessage: "Failed" }));
                    break;
                case types_1.ReindexStatus.paused:
                    buttonProps.color = 'warning';
                    buttonProps.iconSide = 'left';
                    buttonProps.iconType = 'pause';
                    buttonContent = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.reindexButton.pausedLabel", defaultMessage: "Paused" }));
                case types_1.ReindexStatus.cancelled:
                    buttonProps.color = 'danger';
                    buttonProps.iconSide = 'left';
                    buttonProps.iconType = 'cross';
                    buttonContent = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.reindexing.reindexButton.cancelledLabel", defaultMessage: "Cancelled" }));
                    break;
            }
        }
        return (react_1.default.createElement(react_1.Fragment, null,
            react_1.default.createElement(eui_1.EuiButton, Object.assign({}, buttonProps), buttonContent),
            flyoutVisible && (react_1.default.createElement(flyout_1.ReindexFlyout, { indexName: indexName, closeFlyout: this.closeFlyout, reindexState: reindexState, startReindex: this.startReindex, cancelReindex: this.cancelReindex }))));
    }
    newService() {
        return new polling_service_1.ReindexPollingService(this.props.indexName);
    }
    subscribeToUpdates() {
        this.service.updateStatus();
        this.subscription = this.service.status$.subscribe(reindexState => this.setState({ reindexState }));
    }
    unsubscribeToUpdates() {
        if (this.subscription) {
            this.subscription.unsubscribe();
            delete this.subscription;
        }
        if (this.service) {
            this.service.stopPolling();
        }
    }
    async sendUIReindexTelemetryInfo(uiReindexAction) {
        await kfetch_1.kfetch({
            pathname: '/api/upgrade_assistant/telemetry/ui_reindex',
            method: 'PUT',
            body: JSON.stringify(lodash_1.set({}, uiReindexAction, true)),
        });
    }
}
exports.ReindexButton = ReindexButton;

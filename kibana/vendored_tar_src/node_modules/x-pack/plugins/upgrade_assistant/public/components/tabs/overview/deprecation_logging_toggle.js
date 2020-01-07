"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const axios_1 = tslib_1.__importDefault(require("axios"));
const react_1 = tslib_1.__importDefault(require("react"));
const eui_1 = require("@elastic/eui");
const react_2 = require("@kbn/i18n/react");
const chrome_1 = tslib_1.__importDefault(require("ui/chrome"));
const types_1 = require("../../types");
class DeprecationLoggingToggleUI extends react_1.default.Component {
    constructor(props) {
        super(props);
        this.loadData = async () => {
            try {
                this.setState({ loadingState: types_1.LoadingState.Loading });
                const resp = await axios_1.default.get(chrome_1.default.addBasePath('/api/upgrade_assistant/deprecation_logging'));
                this.setState({
                    loadingState: types_1.LoadingState.Success,
                    loggingEnabled: resp.data.isEnabled,
                });
            }
            catch (e) {
                this.setState({ loadingState: types_1.LoadingState.Error });
            }
        };
        this.toggleLogging = async () => {
            try {
                // Optimistically toggle the UI
                const newEnabled = !this.state.loggingEnabled;
                this.setState({ loadingState: types_1.LoadingState.Loading, loggingEnabled: newEnabled });
                const resp = await axios_1.default.put(chrome_1.default.addBasePath('/api/upgrade_assistant/deprecation_logging'), {
                    isEnabled: newEnabled,
                }, {
                    headers: {
                        'kbn-xsrf': chrome_1.default.getXsrfToken(),
                    },
                });
                this.setState({
                    loadingState: types_1.LoadingState.Success,
                    loggingEnabled: resp.data.isEnabled,
                });
            }
            catch (e) {
                this.setState({ loadingState: types_1.LoadingState.Error });
            }
        };
        this.state = {
            loadingState: types_1.LoadingState.Loading,
        };
    }
    componentWillMount() {
        this.loadData();
    }
    render() {
        const { loggingEnabled, loadingState } = this.state;
        // Show a spinner until we've done the initial load.
        if (loadingState === types_1.LoadingState.Loading && loggingEnabled === undefined) {
            return react_1.default.createElement(eui_1.EuiLoadingSpinner, { size: "l" });
        }
        return (react_1.default.createElement(eui_1.EuiSwitch, { id: "xpack.upgradeAssistant.overviewTab.steps.deprecationLogsStep.enableDeprecationLoggingToggleSwitch", "data-test-subj": "upgradeAssistantDeprecationToggle", label: this.renderLoggingState(), checked: loggingEnabled, onChange: this.toggleLogging, disabled: loadingState === types_1.LoadingState.Loading || loadingState === types_1.LoadingState.Error }));
    }
    renderLoggingState() {
        const { intl } = this.props;
        const { loggingEnabled, loadingState } = this.state;
        if (loadingState === types_1.LoadingState.Error) {
            return intl.formatMessage({
                id: 'xpack.upgradeAssistant.overviewTab.steps.deprecationLogsStep.enableDeprecationLoggingToggleSwitch.errorLabel',
                defaultMessage: 'Could not load logging state',
            });
        }
        else if (loggingEnabled) {
            return intl.formatMessage({
                id: 'xpack.upgradeAssistant.overviewTab.steps.deprecationLogsStep.enableDeprecationLoggingToggleSwitch.enabledLabel',
                defaultMessage: 'On',
            });
        }
        else {
            return intl.formatMessage({
                id: 'xpack.upgradeAssistant.overviewTab.steps.deprecationLogsStep.enableDeprecationLoggingToggleSwitch.disabledLabel',
                defaultMessage: 'Off',
            });
        }
    }
}
exports.DeprecationLoggingToggleUI = DeprecationLoggingToggleUI;
exports.DeprecationLoggingToggle = react_2.injectI18n(DeprecationLoggingToggleUI);

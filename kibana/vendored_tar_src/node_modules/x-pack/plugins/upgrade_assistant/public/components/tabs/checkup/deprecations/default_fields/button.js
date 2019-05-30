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
const kfetch_1 = require("ui/kfetch");
const types_1 = require("../../../../types");
/**
 * Field types used by Metricbeat to generate the default_field setting.
 * Matches Beats code here:
 * https://github.com/elastic/beats/blob/eee127cb59b56f2ed7c7e317398c3f79c4158216/libbeat/template/processor.go#L104
 */
const BEAT_DEFAULT_FIELD_TYPES = new Set(['keyword', 'text', 'ip']);
const BEAT_OTHER_DEFAULT_FIELDS = new Set(['fields.*']);
/**
 * Renders a button if given index is a valid Metricbeat index to add a default_field setting.
 */
class FixDefaultFieldsButton extends react_1.default.Component {
    constructor(props) {
        super(props);
        this.isBeatsIndex = () => {
            const { indexName } = this.props;
            return indexName.startsWith('metricbeat-') || indexName.startsWith('filebeat-');
        };
        this.fixBeatsIndex = async () => {
            if (!this.isBeatsIndex()) {
                return;
            }
            this.setState({
                fixLoadingState: types_1.LoadingState.Loading,
            });
            try {
                await kfetch_1.kfetch({
                    pathname: `/api/upgrade_assistant/add_query_default_field/${this.props.indexName}`,
                    method: 'POST',
                    body: JSON.stringify({
                        fieldTypes: [...BEAT_DEFAULT_FIELD_TYPES],
                        otherFields: [...BEAT_OTHER_DEFAULT_FIELDS],
                    }),
                });
                this.setState({
                    fixLoadingState: types_1.LoadingState.Success,
                });
            }
            catch (e) {
                this.setState({
                    fixLoadingState: types_1.LoadingState.Error,
                });
            }
        };
        this.state = {};
    }
    render() {
        const { fixLoadingState } = this.state;
        if (!this.isBeatsIndex()) {
            return null;
        }
        const buttonProps = { size: 's', onClick: this.fixBeatsIndex };
        let buttonContent;
        switch (fixLoadingState) {
            case types_1.LoadingState.Loading:
                buttonProps.disabled = true;
                buttonProps.isLoading = true;
                buttonContent = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.fixMetricbeatIndexButton.fixingLabel", defaultMessage: "Fixing\u2026" }));
                break;
            case types_1.LoadingState.Success:
                buttonProps.iconSide = 'left';
                buttonProps.iconType = 'check';
                buttonProps.disabled = true;
                buttonContent = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.fixMetricbeatIndexButton.fixedLabel", defaultMessage: "Fixed" }));
                break;
            case types_1.LoadingState.Error:
                buttonProps.color = 'danger';
                buttonProps.iconSide = 'left';
                buttonProps.iconType = 'cross';
                buttonContent = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.fixMetricbeatIndexButton.failedLabel", defaultMessage: "Failed" }));
                break;
            default:
                buttonContent = (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.fixMetricbeatIndexButton.reindexLabel", defaultMessage: "Fix" }));
        }
        return react_1.default.createElement(eui_1.EuiButton, Object.assign({}, buttonProps), buttonContent);
    }
}
exports.FixDefaultFieldsButton = FixDefaultFieldsButton;

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const react_1 = require("@kbn/i18n/react");
const react_2 = tslib_1.__importStar(require("react"));
const job_queue_client_1 = require("../lib/job_queue_client");
class ReportErrorButtonUi extends react_2.Component {
    constructor(props) {
        super(props);
        this.togglePopover = () => {
            this.setState(prevState => {
                return { isPopoverOpen: !prevState.isPopoverOpen };
            });
            if (!this.state.error) {
                this.loadError();
            }
        };
        this.closePopover = () => {
            this.setState({ isPopoverOpen: false });
        };
        this.loadError = async () => {
            this.setState({ isLoading: true });
            try {
                const reportContent = await job_queue_client_1.jobQueueClient.getContent(this.props.jobId);
                if (this.mounted) {
                    this.setState({ isLoading: false, error: reportContent.content });
                }
            }
            catch (kfetchError) {
                if (this.mounted) {
                    this.setState({
                        isLoading: false,
                        calloutTitle: this.props.intl.formatMessage({
                            id: 'xpack.reporting.errorButton.unableToFetchReportContentTitle',
                            defaultMessage: 'Unable to fetch report content',
                        }),
                        error: kfetchError.message,
                    });
                }
            }
        };
        this.state = {
            isLoading: false,
            isPopoverOpen: false,
            calloutTitle: props.intl.formatMessage({
                id: 'xpack.reporting.errorButton.unableToGenerateReportTitle',
                defaultMessage: 'Unable to generate report',
            }),
        };
    }
    render() {
        const button = (react_2.default.createElement(eui_1.EuiButtonIcon, { onClick: this.togglePopover, iconType: "alert", color: 'danger', "aria-label": this.props.intl.formatMessage({
                id: 'xpack.reporting.errorButton.showReportErrorAriaLabel',
                defaultMessage: 'Show report error',
            }) }));
        return (react_2.default.createElement(eui_1.EuiPopover, { id: "popover", button: button, isOpen: this.state.isPopoverOpen, closePopover: this.closePopover, anchorPosition: "downRight" },
            react_2.default.createElement(eui_1.EuiCallOut, { color: "danger", title: this.state.calloutTitle },
                react_2.default.createElement("p", null, this.state.error))));
    }
    componentWillUnmount() {
        this.mounted = false;
    }
    componentDidMount() {
        this.mounted = true;
    }
}
exports.ReportErrorButton = react_1.injectI18n(ReportErrorButtonUi);

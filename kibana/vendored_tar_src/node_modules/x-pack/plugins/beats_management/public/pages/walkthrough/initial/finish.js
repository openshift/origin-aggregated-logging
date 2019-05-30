"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const eui_1 = require("@elastic/eui");
const react_1 = require("@kbn/i18n/react");
const react_2 = tslib_1.__importDefault(require("react"));
class FinishWalkthrough extends react_2.default.Component {
    constructor(props) {
        super(props);
        this.assignTagToBeat = async () => {
            const { intl } = this.props;
            if (!this.props.urlState.enrollmentToken) {
                return alert(intl.formatMessage({
                    id: 'xpack.beatsManagement.enrollBeat.assignTagToBeatInvalidURLNoTokenFountTitle',
                    defaultMessage: 'Invalid URL, no enrollmentToken found',
                }));
            }
            if (!this.props.urlState.createdTag) {
                return alert(intl.formatMessage({
                    id: 'xpack.beatsManagement.enrollBeat.assignTagToBeatInvalidURLNoTagFoundTitle',
                    defaultMessage: 'Invalid URL, no createdTag found',
                }));
            }
            const beat = await this.props.libs.beats.getBeatWithToken(this.props.urlState.enrollmentToken);
            if (!beat) {
                return alert(intl.formatMessage({
                    id: 'xpack.beatsManagement.enrollBeat.assignTagToBeatNotEnrolledProperlyTitle',
                    defaultMessage: 'Error: Beat not enrolled properly',
                }));
            }
            await this.props.containers.beats.assignTagsToBeats([beat], this.props.urlState.createdTag);
            this.props.setUrlState({
                createdTag: '',
                enrollmentToken: '',
            });
            return true;
        };
        this.state = {
            assigned: false,
        };
    }
    componentDidMount() {
        setTimeout(async () => {
            const done = await this.assignTagToBeat();
            if (done) {
                this.setState({
                    assigned: true,
                });
            }
        }, 300);
    }
    render() {
        const { goTo } = this.props;
        return (react_2.default.createElement(eui_1.EuiFlexGroup, { justifyContent: "spaceAround" },
            react_2.default.createElement(eui_1.EuiFlexItem, { grow: false },
                react_2.default.createElement(eui_1.EuiPageContent, null,
                    react_2.default.createElement(eui_1.EuiEmptyPrompt, { iconType: "logoBeats", title: react_2.default.createElement("h2", null,
                            react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.nextStepTitle", defaultMessage: "Your Beat is enrolled. What's next?" })), body: react_2.default.createElement(react_2.default.Fragment, null,
                            react_2.default.createElement("p", null,
                                react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.nextStepDescription", defaultMessage: "Start your Beat to check for configuration errors, then click Done." }))), actions: react_2.default.createElement(eui_1.EuiButton, { fill: true, disabled: !this.state.assigned, onClick: async () => {
                                goTo('/overview/enrolled_beats');
                            } },
                            react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.firstBeatEnrollingDoneButtonLabel", defaultMessage: "Done" })) })))));
    }
}
exports.FinishWalkthroughPage = react_1.injectI18n(FinishWalkthrough);

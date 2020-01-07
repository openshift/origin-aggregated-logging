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
const lodash_1 = require("lodash");
const react_2 = tslib_1.__importDefault(require("react"));
class EnrollBeat extends react_2.default.Component {
    constructor(props) {
        super(props);
        this.pinging = false;
        this.pingForBeatWithToken = async (token) => {
            try {
                const beats = await this.props.getBeatWithToken(token);
                if (!beats) {
                    throw new Error('no beats');
                }
                return beats;
            }
            catch (err) {
                if (this.pinging) {
                    const timeout = (ms) => new Promise(res => setTimeout(res, ms));
                    await timeout(5000);
                    return await this.pingForBeatWithToken(token);
                }
            }
        };
        this.waitForTokenToEnrollBeat = async () => {
            if (this.pinging || !this.props.enrollmentToken) {
                return;
            }
            this.pinging = true;
            const enrolledBeat = (await this.pingForBeatWithToken(this.props.enrollmentToken));
            this.setState({
                enrolledBeat,
            });
            this.props.onBeatEnrolled(enrolledBeat);
            this.pinging = false;
        };
        this.state = {
            enrolledBeat: null,
            hasPolledForBeat: false,
            command: 'sudo {{beatType}}',
            beatType: 'filebeat',
        };
    }
    async componentDidMount() {
        if (!this.props.enrollmentToken) {
            await this.props.createEnrollmentToken();
        }
    }
    render() {
        if (!this.props.enrollmentToken && !this.state.enrolledBeat) {
            return null;
        }
        if (this.props.enrollmentToken && !this.state.enrolledBeat) {
            this.waitForTokenToEnrollBeat();
        }
        const cmdText = `${this.state.command
            .replace('{{beatType}}', this.state.beatType)
            .replace('{{beatTypeInCaps}}', lodash_1.capitalize(this.state.beatType))} enroll ${window.location.protocol}//${window.location.host}${this.props.frameworkBasePath} ${this.props.enrollmentToken}`;
        return (react_2.default.createElement(react_2.default.Fragment, null,
            !this.state.enrolledBeat && (react_2.default.createElement(react_2.default.Fragment, null,
                react_2.default.createElement(eui_1.EuiFlexGroup, null,
                    react_2.default.createElement(eui_1.EuiFlexItem, null,
                        react_2.default.createElement(eui_1.EuiFlexGroup, { gutterSize: "s", alignItems: "center" },
                            react_2.default.createElement(eui_1.EuiFlexItem, { grow: false },
                                react_2.default.createElement(eui_1.EuiTitle, { size: "xs" },
                                    react_2.default.createElement("h3", null,
                                        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.beatTypeTitle", defaultMessage: "Beat type:" }))))),
                        react_2.default.createElement(eui_1.EuiSelect, { value: this.state.beatType, options: [
                                {
                                    value: 'filebeat',
                                    text: 'Filebeat',
                                },
                                {
                                    value: 'metricbeat',
                                    text: 'Metricbeat',
                                },
                            ], onChange: (e) => this.setState({ beatType: e.target.value }), fullWidth: true }))),
                react_2.default.createElement("br", null),
                react_2.default.createElement("br", null),
                react_2.default.createElement(eui_1.EuiFlexGroup, null,
                    react_2.default.createElement(eui_1.EuiFlexItem, null,
                        react_2.default.createElement(eui_1.EuiFlexGroup, { gutterSize: "s", alignItems: "center" },
                            react_2.default.createElement(eui_1.EuiFlexItem, { grow: false },
                                react_2.default.createElement(eui_1.EuiTitle, { size: "xs" },
                                    react_2.default.createElement("h3", null,
                                        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.platformTitle", defaultMessage: "Platform:" }))))),
                        react_2.default.createElement(eui_1.EuiSelect, { value: this.state.command, options: [
                                {
                                    value: `sudo {{beatType}}`,
                                    text: 'DEB / RPM',
                                },
                                {
                                    value: `PS C:\\Program Files\\{{beatTypeInCaps}}> {{beatType}}.exe`,
                                    text: 'Windows',
                                },
                                {
                                    value: `./{{beatType}}`,
                                    text: 'MacOS',
                                },
                            ], onChange: (e) => this.setState({ command: e.target.value }), fullWidth: true }))),
                react_2.default.createElement("br", null),
                react_2.default.createElement("br", null),
                this.state.command && (react_2.default.createElement(eui_1.EuiFlexGroup, null,
                    react_2.default.createElement(eui_1.EuiFlexItem, null,
                        react_2.default.createElement(eui_1.EuiFlexGroup, { justifyContent: "spaceBetween", alignItems: "flexEnd" },
                            react_2.default.createElement(eui_1.EuiFlexItem, { grow: false },
                                react_2.default.createElement(eui_1.EuiTitle, { size: "xs" },
                                    react_2.default.createElement("h3", null,
                                        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.yourBeatTypeHostTitle", defaultMessage: "On the host where your {beatType} is installed, run:", values: {
                                                beatType: lodash_1.capitalize(this.state.beatType),
                                            } })))),
                            react_2.default.createElement(eui_1.EuiFlexItem, { className: "homTutorial__instruction", grow: false },
                                react_2.default.createElement(eui_1.EuiCopy, { textToCopy: cmdText }, (copy) => (react_2.default.createElement(eui_1.EuiButton, { size: "s", onClick: copy },
                                    react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.copyButtonLabel", defaultMessage: "Copy command" })))))),
                        react_2.default.createElement("div", { className: "eui-textBreakAll" },
                            react_2.default.createElement(eui_1.EuiSpacer, { size: "m" }),
                            react_2.default.createElement(eui_1.EuiCodeBlock, { language: "sh" }, `$ ${cmdText}`)),
                        react_2.default.createElement(eui_1.EuiSpacer, { size: "m" }),
                        react_2.default.createElement(eui_1.EuiFlexGroup, null,
                            react_2.default.createElement(eui_1.EuiFlexItem, null,
                                react_2.default.createElement(eui_1.EuiFlexGroup, { gutterSize: "s", alignItems: "center" },
                                    react_2.default.createElement(eui_1.EuiFlexItem, { grow: false },
                                        react_2.default.createElement(eui_1.EuiTitle, { size: "xs" },
                                            react_2.default.createElement("h3", null,
                                                react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.waitingBeatTypeToEnrollTitle", defaultMessage: "Waiting for {beatType} to enroll\u2026", values: {
                                                        beatType: lodash_1.capitalize(this.state.beatType),
                                                    } }))))))),
                        react_2.default.createElement("br", null),
                        react_2.default.createElement(eui_1.EuiLoadingSpinner, { size: "l" })))))),
            this.state.enrolledBeat && (react_2.default.createElement(eui_1.EuiModalBody, null,
                react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.beatEnrolledTitle", defaultMessage: "The Beat is now enrolled in central management:" }),
                react_2.default.createElement("br", null),
                react_2.default.createElement("br", null),
                react_2.default.createElement("br", null),
                react_2.default.createElement(eui_1.EuiBasicTable, { items: [this.state.enrolledBeat], columns: [
                        {
                            field: 'type',
                            name: (react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.beatTypeColumnName", defaultMessage: "Beat Type" })),
                            sortable: false,
                        },
                        {
                            field: 'version',
                            name: (react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.versionColumnName", defaultMessage: "Version" })),
                            sortable: false,
                        },
                        {
                            field: 'host_name',
                            name: (react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.hostnameColumnName", defaultMessage: "Hostname" })),
                            sortable: false,
                        },
                    ] }),
                react_2.default.createElement("br", null),
                react_2.default.createElement("br", null)))));
    }
}
exports.EnrollBeat = EnrollBeat;

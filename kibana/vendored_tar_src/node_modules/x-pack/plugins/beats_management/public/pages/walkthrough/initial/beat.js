"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const eui_1 = require("@elastic/eui");
const react_1 = tslib_1.__importStar(require("react"));
const enroll_beats_1 = require("../../../components/enroll_beats");
class BeatsInitialEnrollmentPage extends react_1.Component {
    constructor(props) {
        super(props);
        this.onBeatEnrolled = () => {
            this.setState({
                readyToContinue: true,
            });
        };
        this.createEnrollmentToken = async () => {
            const enrollmentToken = await this.props.libs.tokens.createEnrollmentTokens();
            this.props.setUrlState({
                enrollmentToken: enrollmentToken[0],
            });
        };
        this.state = {
            readyToContinue: false,
        };
    }
    render() {
        return (react_1.default.createElement(react_1.default.Fragment, null,
            react_1.default.createElement(enroll_beats_1.EnrollBeat, { frameworkBasePath: this.props.libs.framework.info.basePath, enrollmentToken: this.props.urlState.enrollmentToken || '', getBeatWithToken: this.props.libs.beats.getBeatWithToken, createEnrollmentToken: this.createEnrollmentToken, onBeatEnrolled: this.onBeatEnrolled }),
            this.state.readyToContinue && (react_1.default.createElement(react_1.default.Fragment, null,
                react_1.default.createElement(eui_1.EuiButton, { size: "s", color: "primary", style: { marginLeft: 10 }, onClick: async () => {
                        this.props.goTo('/walkthrough/initial/tag');
                    } }, "Continue")))));
    }
}
exports.BeatsInitialEnrollmentPage = BeatsInitialEnrollmentPage;

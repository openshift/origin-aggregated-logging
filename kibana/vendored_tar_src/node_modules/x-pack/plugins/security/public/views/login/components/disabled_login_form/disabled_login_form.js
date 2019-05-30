"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const react_1 = tslib_1.__importStar(require("react"));
class DisabledLoginForm extends react_1.Component {
    render() {
        return (react_1.default.createElement(eui_1.EuiPanel, null,
            react_1.default.createElement(eui_1.EuiText, { color: "danger", style: { textAlign: 'center' } },
                react_1.default.createElement("p", null, this.props.title)),
            react_1.default.createElement(eui_1.EuiText, { style: { textAlign: 'center' } },
                react_1.default.createElement("p", null, this.props.message))));
    }
}
exports.DisabledLoginForm = DisabledLoginForm;

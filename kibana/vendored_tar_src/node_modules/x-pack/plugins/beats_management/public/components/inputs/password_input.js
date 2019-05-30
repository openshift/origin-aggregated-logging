"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
// @ts-ignore currently no definition for EuiFieldPassword
const eui_1 = require("@elastic/eui");
const formsy_react_1 = require("formsy-react");
const react_1 = tslib_1.__importStar(require("react"));
class FieldPassword extends react_1.Component {
    constructor(props) {
        super(props);
        this.handleChange = (e) => {
            const { value } = e.currentTarget;
            this.props.setValue(value);
            if (this.props.onChange) {
                this.props.onChange(e, value);
            }
            if (this.props.instantValidation) {
                this.showError();
            }
        };
        this.handleBlur = (e) => {
            this.showError();
            if (this.props.onBlur) {
                this.props.onBlur(e, e.currentTarget.value);
            }
        };
        this.showError = () => this.setState({ allowError: true });
        this.state = {
            allowError: false,
        };
    }
    componentDidMount() {
        const { defaultValue, setValue } = this.props;
        if (defaultValue) {
            setValue(defaultValue);
        }
    }
    render() {
        const { id, required, label, getValue, isValid, isPristine, getErrorMessage, fullWidth, className, disabled, helpText, onBlur, } = this.props;
        const { allowError } = this.state;
        const error = !isPristine() && !isValid() && allowError;
        return (react_1.default.createElement(eui_1.EuiFormRow, { id: id, label: label, helpText: helpText, isInvalid: !disabled && error, error: !disabled && error ? getErrorMessage() : [] },
            react_1.default.createElement(eui_1.EuiFieldPassword, { id: id, name: name, value: getValue() || '', isInvalid: !disabled && error, onChange: this.handleChange, onBlur: onBlur, fullWidth: fullWidth, disabled: disabled, required: required, className: className })));
    }
}
exports.FormsyEuiPasswordText = formsy_react_1.withFormsy(FieldPassword);

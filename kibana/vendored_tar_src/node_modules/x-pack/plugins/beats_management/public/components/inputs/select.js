"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
// @ts-ignore
const formsy_react_1 = require("formsy-react");
const react_1 = tslib_1.__importStar(require("react"));
const FixedSelect = eui_1.EuiSelect;
class FieldSelect extends react_1.Component {
    constructor() {
        super(...arguments);
        this.state = { allowError: false };
        this.handleChange = (e) => {
            const { value } = e.currentTarget;
            this.props.setValue(value);
            if (this.props.onChange) {
                this.props.onChange(e, e.currentTarget.value);
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
    }
    componentDidMount() {
        const { defaultValue, setValue } = this.props;
        if (defaultValue) {
            setValue(defaultValue);
        }
    }
    componentWillReceiveProps(nextProps) {
        if (nextProps.isFormSubmitted()) {
            this.showError();
        }
    }
    render() {
        const { id, required, label, options, getValue, isValid, isPristine, getErrorMessage, fullWidth, className, disabled, helpText, } = this.props;
        const { allowError } = this.state;
        const error = !isPristine() && !isValid() && allowError;
        return (react_1.default.createElement(eui_1.EuiFormRow, { id: id, label: label, helpText: helpText, isInvalid: !disabled && error, error: !disabled && error ? getErrorMessage() : [] },
            react_1.default.createElement(FixedSelect, { id: id, name: name, value: getValue() || '', options: options, isInvalid: !disabled && error, onChange: this.handleChange, onBlur: this.handleBlur, fullWidth: fullWidth, disabled: disabled, required: required, className: className })));
    }
}
FieldSelect.defaultProps = {
    passRequiredToField: true,
};
exports.FormsyEuiSelect = formsy_react_1.withFormsy(FieldSelect);

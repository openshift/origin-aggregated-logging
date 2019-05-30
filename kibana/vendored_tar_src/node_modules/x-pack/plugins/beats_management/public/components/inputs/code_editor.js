"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
// @ts-ignore
const eui_1 = require("@elastic/eui");
// @ts-ignore
const formsy_react_1 = require("formsy-react");
const react_1 = tslib_1.__importStar(require("react"));
class CodeEditor extends react_1.Component {
    constructor() {
        super(...arguments);
        this.state = { allowError: false };
        this.handleChange = (value) => {
            this.props.setValue(value);
            if (this.props.onChange) {
                this.props.onChange(value);
            }
            if (this.props.instantValidation) {
                this.showError();
            }
        };
        this.handleBlur = () => {
            this.showError();
            if (this.props.onBlur) {
                this.props.onBlur();
            }
        };
        this.showError = () => this.setState({ allowError: true });
    }
    componentDidMount() {
        const { defaultValue, setValue } = this.props;
        setValue(defaultValue || '');
    }
    componentWillReceiveProps(nextProps) {
        if (nextProps.isFormSubmitted()) {
            this.showError();
        }
    }
    render() {
        const { id, label, isReadOnly, isValid, getValue, isPristine, getErrorMessage, mode, fullWidth, className, helpText, } = this.props;
        const { allowError } = this.state;
        const error = !isPristine() && !isValid() && allowError;
        return (react_1.default.createElement(eui_1.EuiFormRow, { id: id, label: label, helpText: helpText, isInvalid: error, error: error ? getErrorMessage() : [] },
            react_1.default.createElement(eui_1.EuiCodeEditor, { id: id, name: name, mode: mode, theme: "github", value: getValue() || '', isReadOnly: isReadOnly || false, isInvalid: error, onChange: this.handleChange, onBlur: this.handleBlur, width: fullWidth ? '100%' : undefined, className: className })));
    }
}
CodeEditor.defaultProps = {
    passRequiredToField: true,
};
exports.FormsyEuiCodeEditor = formsy_react_1.withFormsy(CodeEditor);

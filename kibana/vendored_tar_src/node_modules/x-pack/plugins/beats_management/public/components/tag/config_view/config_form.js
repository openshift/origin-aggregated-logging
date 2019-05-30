"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
// @ts-ignore
const i18n_1 = require("@kbn/i18n");
const formsy_react_1 = tslib_1.__importDefault(require("formsy-react"));
const lodash_1 = require("lodash");
const react_1 = tslib_1.__importDefault(require("react"));
const inputs_1 = require("../../inputs");
class ConfigFormUi extends react_1.default.Component {
    constructor(props) {
        super(props);
        this.form = react_1.default.createRef();
        this.enableButton = () => {
            this.setState({
                canSubmit: true,
            });
            this.props.canSubmit(true);
        };
        this.disableButton = () => {
            this.setState({
                canSubmit: false,
            });
            this.props.canSubmit(false);
        };
        this.submit = () => {
            if (this.form.current && this.props.onSubmit) {
                this.form.current.click();
            }
        };
        this.onValidSubmit = (model) => {
            if (!this.props.onSubmit) {
                return;
            }
            this.props.onSubmit(model);
        };
        this.state = {
            canSubmit: false,
        };
    }
    render() {
        return (react_1.default.createElement("div", null,
            react_1.default.createElement("br", null),
            react_1.default.createElement(formsy_react_1.default, { onValidSubmit: this.onValidSubmit, onValid: this.enableButton, onInvalid: this.disableButton },
                this.props.schema.configs.map(schema => {
                    switch (schema.ui.type) {
                        case 'input':
                            return (react_1.default.createElement(inputs_1.FormsyEuiFieldText, { key: schema.id, id: schema.id, defaultValue: lodash_1.get(this.props, `values.config.${schema.id}`, schema.defaultValue), name: schema.id, disabled: !this.props.onSubmit, helpText: schema.ui.helpText, placeholder: schema.ui.placeholder, label: schema.ui.label, validationError: schema.error, required: schema.required || false }));
                        case 'password':
                            return (react_1.default.createElement(inputs_1.FormsyEuiPasswordText, { key: schema.id, id: schema.id, disabled: !this.props.onSubmit, defaultValue: lodash_1.get(this.props, `values.config.${schema.id}`, schema.defaultValue), name: schema.id, placeholder: schema.ui.placeholder, helpText: schema.ui.helpText, label: schema.ui.label, validationError: schema.error, required: schema.required || false }));
                        case 'multi-input':
                            return (react_1.default.createElement(inputs_1.FormsyEuiMultiFieldText, { key: schema.id, id: schema.id, disabled: !this.props.onSubmit, defaultValue: lodash_1.get(this.props, `values.config.${schema.id}`, schema.defaultValue), name: schema.id, placeholder: schema.ui.placeholder, helpText: schema.ui.helpText, label: schema.ui.label, validationError: schema.error, required: schema.required }));
                        case 'select':
                            return (react_1.default.createElement(inputs_1.FormsyEuiSelect, { key: schema.id, id: schema.id, name: schema.id, disabled: !this.props.onSubmit, defaultValue: lodash_1.get(this.props, `values.config.${schema.id}`, schema.defaultValue), helpText: schema.ui.helpText, label: schema.ui.label, options: [
                                    {
                                        value: '',
                                        text: i18n_1.i18n.translate('xpack.beatsManagement.table.selectOptionLabel', {
                                            defaultMessage: 'Please Select An Option',
                                        }),
                                    },
                                ].concat(schema.options || []), validationError: schema.error, required: schema.required }));
                        case 'code':
                            return (react_1.default.createElement(inputs_1.FormsyEuiCodeEditor, { key: `${schema.id}-${this.props.id}`, mode: "yaml", disabled: !this.props.onSubmit, id: schema.id, defaultValue: lodash_1.get(this.props, `values.config.${schema.id}`, schema.defaultValue), name: schema.id, helpText: schema.ui.helpText, label: schema.ui.label, options: schema.options ? schema.options : [], validationError: schema.error, required: schema.required }));
                    }
                }),
                this.props.schema && (react_1.default.createElement(inputs_1.FormsyEuiCodeEditor, { mode: "yaml", disabled: !this.props.onSubmit, id: 'other', defaultValue: lodash_1.get(this.props, `values.config.other`, ''), name: 'other', helpText: i18n_1.i18n.translate('xpack.beatsManagement.config.otherConfigDescription', {
                        defaultMessage: 'Use YAML format to specify other settings for the Filebeat Input',
                    }), label: i18n_1.i18n.translate('xpack.beatsManagement.config.otherConfigLabel', {
                        defaultMessage: 'Other Config',
                    }), validationError: i18n_1.i18n.translate('xpack.beatsManagement.config.other.error', {
                        defaultMessage: 'Use valid YAML format',
                    }), required: false })),
                this.props.onSubmit && (react_1.default.createElement("button", { type: "submit", style: { display: 'none' }, disabled: !this.state.canSubmit, ref: this.form })))));
    }
}
exports.ConfigForm = ConfigFormUi;

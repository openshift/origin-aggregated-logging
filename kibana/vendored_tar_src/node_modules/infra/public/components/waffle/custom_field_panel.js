"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
var _a;
"use strict";
const eui_1 = require("@elastic/eui");
const react_1 = require("@kbn/i18n/react");
const react_2 = tslib_1.__importDefault(require("react"));
const initialState = {
    selectedOptions: [],
};
exports.CustomFieldPanel = react_1.injectI18n((_a = class extends react_2.default.PureComponent {
        constructor() {
            super(...arguments);
            this.state = initialState;
            this.handleSubmit = () => {
                this.props.onSubmit(this.state.selectedOptions[0].label);
            };
            this.handleFieldSelection = (selectedOptions) => {
                this.setState({ selectedOptions });
            };
        }
        render() {
            const { fields, intl } = this.props;
            const options = fields
                .filter(f => f.aggregatable && f.type === 'string')
                .map(f => ({ label: f.name }));
            return (react_2.default.createElement("div", { style: { padding: 16 } },
                react_2.default.createElement(eui_1.EuiForm, null,
                    react_2.default.createElement(eui_1.EuiFormRow, { label: intl.formatMessage({
                            id: 'xpack.infra.waffle.customGroupByFieldLabel',
                            defaultMessage: 'Field',
                        }), helpText: intl.formatMessage({
                            id: 'xpack.infra.waffle.customGroupByHelpText',
                            defaultMessage: 'This is the field used for the terms aggregation',
                        }), compressed: true },
                        react_2.default.createElement(eui_1.EuiComboBox, { placeholder: intl.formatMessage({
                                id: 'xpack.infra.waffle.customGroupByDropdownPlacehoder',
                                defaultMessage: 'Select one',
                            }), singleSelection: { asPlainText: true }, selectedOptions: this.state.selectedOptions, options: options, onChange: this.handleFieldSelection, isClearable: false })),
                    react_2.default.createElement(eui_1.EuiButton, { disabled: !this.state.selectedOptions.length, type: "submit", size: "s", fill: true, onClick: this.handleSubmit }, "Add"))));
        }
    },
    _a.displayName = 'CustomFieldPanel',
    _a));

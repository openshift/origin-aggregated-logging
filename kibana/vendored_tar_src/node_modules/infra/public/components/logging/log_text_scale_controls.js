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
const React = tslib_1.__importStar(require("react"));
const log_text_scale_1 = require("../../../common/log_text_scale");
class LogTextScaleControls extends React.PureComponent {
    constructor() {
        super(...arguments);
        this.setTextScale = (textScale) => {
            if (log_text_scale_1.isTextScale(textScale)) {
                this.props.setTextScale(textScale);
            }
        };
    }
    render() {
        const { availableTextScales, textScale } = this.props;
        return (React.createElement(eui_1.EuiFormRow, { label: React.createElement(react_1.FormattedMessage, { id: "xpack.infra.logs.customizeLogs.textSizeFormRowLabel", defaultMessage: "Text Size" }) },
            React.createElement(eui_1.EuiRadioGroup, { options: availableTextScales.map((availableTextScale) => ({
                    id: availableTextScale.toString(),
                    label: (React.createElement(react_1.FormattedMessage, { id: "xpack.infra.logs.customizeLogs.textSizeRadioGroup", defaultMessage: "{textScale, select,\n                  small {Small}\n                  medium {Medium}\n                  large {Large}\n                  other {{textScale}}\n                }", values: {
                            textScale: availableTextScale,
                        } })),
                })), idSelected: textScale, onChange: this.setTextScale })));
    }
}
exports.LogTextScaleControls = LogTextScaleControls;

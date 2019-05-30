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
class LogMinimapScaleControls extends React.PureComponent {
    constructor() {
        super(...arguments);
        this.handleScaleChange = (intervalSizeDescriptorKey) => {
            const { availableIntervalSizes, setIntervalSize } = this.props;
            const [sizeDescriptor] = availableIntervalSizes.filter(intervalKeyEquals(intervalSizeDescriptorKey));
            if (sizeDescriptor) {
                setIntervalSize(sizeDescriptor.intervalSize);
            }
        };
    }
    render() {
        const { availableIntervalSizes, intervalSize } = this.props;
        const [currentSizeDescriptor] = availableIntervalSizes.filter(intervalSizeEquals(intervalSize));
        return (React.createElement(eui_1.EuiFormRow, { label: React.createElement(react_1.FormattedMessage, { id: "xpack.infra.logs.customizeLogs.minimapScaleFormRowLabel", defaultMessage: "Minimap Scale" }) },
            React.createElement(eui_1.EuiRadioGroup, { options: availableIntervalSizes.map(sizeDescriptor => ({
                    id: getIntervalSizeDescriptorKey(sizeDescriptor),
                    label: sizeDescriptor.label,
                })), onChange: this.handleScaleChange, idSelected: getIntervalSizeDescriptorKey(currentSizeDescriptor) })));
    }
}
exports.LogMinimapScaleControls = LogMinimapScaleControls;
const getIntervalSizeDescriptorKey = (sizeDescriptor) => `${sizeDescriptor.intervalSize}`;
const intervalKeyEquals = (key) => (sizeDescriptor) => getIntervalSizeDescriptorKey(sizeDescriptor) === key;
const intervalSizeEquals = (size) => (sizeDescriptor) => sizeDescriptor.intervalSize === size;

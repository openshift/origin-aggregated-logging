"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importDefault(require("react"));
const sections_1 = require("./sections");
class Section extends react_1.default.PureComponent {
    render() {
        const metric = this.props.metrics.find(m => m.id === this.props.section.id);
        if (!metric) {
            return null;
        }
        let sectionProps = {};
        if (this.props.section.type === 'chart') {
            sectionProps = {
                onChangeRangeTime: this.props.onChangeRangeTime,
                crosshairValue: this.props.crosshairValue,
                onCrosshairUpdate: this.props.onCrosshairUpdate,
                isLiveStreaming: this.props.isLiveStreaming,
                stopLiveStreaming: this.props.stopLiveStreaming,
            };
        }
        const Component = sections_1.sections[this.props.section.type];
        return react_1.default.createElement(Component, Object.assign({ section: this.props.section, metric: metric }, sectionProps));
    }
}
exports.Section = Section;

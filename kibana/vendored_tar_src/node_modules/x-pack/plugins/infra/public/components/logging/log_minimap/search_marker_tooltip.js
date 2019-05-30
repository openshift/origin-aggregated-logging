"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const React = tslib_1.__importStar(require("react"));
const auto_sizer_1 = require("../../auto_sizer");
class SearchMarkerTooltip extends React.PureComponent {
    render() {
        const { children, markerPosition } = this.props;
        return (React.createElement(eui_1.EuiPortal, null,
            React.createElement("div", { style: { position: 'relative' } },
                React.createElement(auto_sizer_1.AutoSizer, { content: false, bounds: true }, ({ measureRef, bounds: { width, height } }) => {
                    const { top, left } = width && height
                        ? eui_1.calculatePopoverPosition(markerPosition, { width, height }, 'left', 16, [
                            'left',
                        ])
                        : {
                            left: -9999,
                            top: 0,
                        };
                    return (React.createElement("div", { className: "euiToolTip euiToolTip--left euiToolTipPopover", style: {
                            left,
                            top,
                        }, ref: measureRef }, children));
                }))));
    }
}
exports.SearchMarkerTooltip = SearchMarkerTooltip;

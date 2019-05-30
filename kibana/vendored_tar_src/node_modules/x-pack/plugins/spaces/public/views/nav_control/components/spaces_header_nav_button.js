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
class SpacesHeaderNavButton extends react_1.Component {
    render() {
        return (react_1.default.createElement(eui_1.EuiHeaderSectionItemButton, { "aria-controls": "headerSpacesMenuList", "aria-expanded": this.props.spaceSelectorShown, "aria-haspopup": "true", "aria-label": this.props.linkTitle, title: this.props.linkTitle, onClick: this.props.toggleSpaceSelector }, this.props.linkIcon));
    }
}
exports.SpacesHeaderNavButton = SpacesHeaderNavButton;

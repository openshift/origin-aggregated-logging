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
const space_card_1 = require("./space_card");
class SpaceCards extends react_1.Component {
    constructor() {
        super(...arguments);
        this.renderSpace = (space) => (react_1.default.createElement(eui_1.EuiFlexItem, { key: space.id, grow: false },
            react_1.default.createElement(space_card_1.SpaceCard, { space: space, onClick: this.createSpaceClickHandler(space) })));
        this.createSpaceClickHandler = (space) => {
            return () => {
                this.props.onSpaceSelect(space);
            };
        };
    }
    render() {
        return (react_1.default.createElement("div", { className: "spaceCards" },
            react_1.default.createElement(eui_1.EuiFlexGroup, { gutterSize: "l", justifyContent: "center", wrap: true, responsive: false }, this.props.spaces.map(this.renderSpace))));
    }
}
exports.SpaceCards = SpaceCards;

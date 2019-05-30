"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const react_1 = tslib_1.__importDefault(require("react"));
const components_1 = require("../../components");
exports.SpaceCard = (props) => {
    const { space, onClick } = props;
    return (react_1.default.createElement(eui_1.EuiCard, { className: "spaceCard", "data-test-subj": `space-card-${space.id}`, icon: renderSpaceAvatar(space), title: space.name, description: renderSpaceDescription(space), onClick: onClick }));
};
function renderSpaceAvatar(space) {
    // not announcing space name here because the title of the EuiCard that the SpaceAvatar lives in is already
    // announcing it. See https://github.com/elastic/kibana/issues/27748
    return react_1.default.createElement(components_1.SpaceAvatar, { space: space, size: 'l', announceSpaceName: false });
}
function renderSpaceDescription(space) {
    let description = space.description || '';
    const needsTruncation = description.length > 120;
    if (needsTruncation) {
        description = description.substr(0, 120) + '…';
    }
    return (react_1.default.createElement("span", { title: description, className: "eui-textBreakWord euiTextColor--subdued" }, description));
}

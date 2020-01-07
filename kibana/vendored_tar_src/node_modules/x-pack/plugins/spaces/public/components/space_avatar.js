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
const common_1 = require("../../common");
exports.SpaceAvatar = (props) => {
    const { space, size, announceSpaceName, ...rest } = props;
    const spaceName = space.name ? space.name.trim() : '';
    return (react_1.default.createElement(eui_1.EuiAvatar, Object.assign({ type: "space", "data-test-subj": `space-avatar-${space.id}`, name: spaceName }, !announceSpaceName && {
        // provide empty aria-label so EUI doesn't try to provide its own
        'aria-label': '',
        'aria-hidden': true,
    }, { size: size || 'm', initialsLength: common_1.MAX_SPACE_INITIALS, initials: common_1.getSpaceInitials(space), color: common_1.getSpaceColor(space) }, rest)));
};
exports.SpaceAvatar.defaultProps = {
    announceSpaceName: true,
};

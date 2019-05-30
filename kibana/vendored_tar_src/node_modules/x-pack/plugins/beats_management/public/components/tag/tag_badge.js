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
const constants_1 = require("../../../common/constants");
exports.TagBadge = (props) => {
    const { iconType, onClick, onClickAriaLabel, tag } = props;
    const maxIdRenderSize = props.maxIdRenderSize || constants_1.TABLE_CONFIG.TRUNCATE_TAG_LENGTH;
    const idToRender = `${tag.name.substring(0, maxIdRenderSize)}${tag.name.length > maxIdRenderSize ? '...' : ''}`;
    return (react_1.default.createElement(eui_1.EuiBadge, { color: tag.disabled ? 'default' : tag.color || 'primary', iconType: tag.disabled ? 'cross' : iconType, onClick: tag.disabled ? undefined : onClick, onClickAriaLabel: tag.disabled ? undefined : onClickAriaLabel }, idToRender));
};

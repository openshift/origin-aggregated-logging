"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importDefault(require("react"));
const action_schema_1 = require("../action_schema");
const action_control_1 = require("./action_control");
const tag_badge_list_1 = require("./tag_badge_list");
exports.OptionControl = (props) => {
    switch (props.type) {
        case action_schema_1.ActionComponentType.Action:
            if (!props.action) {
                throw Error('Action cannot be undefined');
            }
            return (react_1.default.createElement(action_control_1.ActionControl, { actionHandler: props.actionHandler, action: props.action, danger: props.danger, name: props.name, showWarning: props.showWarning, warningHeading: props.warningHeading, warningMessage: props.warningMessage, disabled: props.disabled }));
        case action_schema_1.ActionComponentType.TagBadgeList:
            if (!props.actionDataKey) {
                throw Error('actionDataKey cannot be undefined');
            }
            if (!props.actionData) {
                throw Error('actionData cannot be undefined');
            }
            return (react_1.default.createElement(tag_badge_list_1.TagBadgeList, { actionHandler: props.actionHandler, action: props.action, name: props.name, items: props.actionData[props.actionDataKey], disabled: props.disabled }));
    }
    return react_1.default.createElement("div", null, "Invalid config");
};

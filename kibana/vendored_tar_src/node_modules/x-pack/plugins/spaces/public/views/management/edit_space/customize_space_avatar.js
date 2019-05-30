"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
// @ts-ignore
const eui_1 = require("@elastic/eui");
const react_1 = require("@kbn/i18n/react");
const react_2 = tslib_1.__importStar(require("react"));
const constants_1 = require("../../../../common/constants");
const space_attributes_1 = require("../../../../common/space_attributes");
class CustomizeSpaceAvatarUI extends react_2.Component {
    constructor(props) {
        super(props);
        this.initialsRef = null;
        this.getCustomizeFields = () => {
            const { space, intl } = this.props;
            const { initialsHasFocus, pendingInitials } = this.state;
            return (react_2.default.createElement(react_2.Fragment, null,
                react_2.default.createElement(eui_1.EuiFlexItem, { grow: false },
                    react_2.default.createElement(eui_1.EuiFormRow, { label: intl.formatMessage({
                            id: 'xpack.spaces.management.customizeSpaceAvatar.initialItemsFormRowLabel',
                            defaultMessage: 'Initials (2 max)',
                        }) },
                        react_2.default.createElement(eui_1.EuiFieldText, { inputRef: this.initialsInputRef, name: "spaceInitials", 
                            // allows input to be cleared or otherwise invalidated while user is editing the initials,
                            // without defaulting to the derived initials provided by `getSpaceInitials`
                            value: initialsHasFocus ? pendingInitials || '' : space_attributes_1.getSpaceInitials(space), onChange: this.onInitialsChange }))),
                react_2.default.createElement(eui_1.EuiFlexItem, { grow: true },
                    react_2.default.createElement(eui_1.EuiFormRow, { label: intl.formatMessage({
                            id: 'xpack.spaces.management.customizeSpaceAvatar.colorFormRowLabel',
                            defaultMessage: 'Color',
                        }) },
                        react_2.default.createElement(eui_1.EuiColorPicker, { color: space_attributes_1.getSpaceColor(space), onChange: this.onColorChange })))));
        };
        this.initialsInputRef = (ref) => {
            if (ref) {
                this.initialsRef = ref;
                this.initialsRef.addEventListener('focus', this.onInitialsFocus);
                this.initialsRef.addEventListener('blur', this.onInitialsBlur);
            }
            else {
                if (this.initialsRef) {
                    this.initialsRef.removeEventListener('focus', this.onInitialsFocus);
                    this.initialsRef.removeEventListener('blur', this.onInitialsBlur);
                    this.initialsRef = null;
                }
            }
        };
        this.onInitialsFocus = () => {
            this.setState({
                initialsHasFocus: true,
                pendingInitials: space_attributes_1.getSpaceInitials(this.props.space),
            });
        };
        this.onInitialsBlur = () => {
            this.setState({
                initialsHasFocus: false,
                pendingInitials: null,
            });
        };
        this.getCustomizeLink = () => {
            return (react_2.default.createElement(eui_1.EuiFlexItem, { grow: false },
                react_2.default.createElement(eui_1.EuiFormRow, { hasEmptyLabelSpace: true },
                    react_2.default.createElement(eui_1.EuiLink, { name: "customize_space_link", onClick: this.showFields },
                        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.customizeSpaceAvatar.customizeLinkText", defaultMessage: "Customize" })))));
        };
        this.showFields = () => {
            this.setState({
                expanded: true,
            });
        };
        this.onInitialsChange = (e) => {
            const initials = (e.target.value || '').substring(0, constants_1.MAX_SPACE_INITIALS);
            this.setState({
                pendingInitials: initials,
            });
            this.props.onChange({
                ...this.props.space,
                initials,
            });
        };
        this.onColorChange = (color) => {
            this.props.onChange({
                ...this.props.space,
                color,
            });
        };
        this.state = {
            expanded: false,
            initialsHasFocus: false,
        };
    }
    render() {
        return this.state.expanded ? this.getCustomizeFields() : this.getCustomizeLink();
    }
}
exports.CustomizeSpaceAvatar = react_1.injectI18n(CustomizeSpaceAvatarUI);

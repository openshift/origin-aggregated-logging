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
const table_1 = require("../../../../common/constants/table");
const tag_badge_1 = require("../../tag/tag_badge");
const index_1 = require("../index");
class TagBadgeList extends react_1.default.Component {
    constructor(props) {
        super(props);
        this.onButtonClick = async () => {
            this.props.actionHandler(index_1.AssignmentActionType.Reload);
            this.setState(prevState => ({
                isPopoverOpen: !prevState.isPopoverOpen,
            }));
        };
        this.closePopover = () => {
            this.setState({
                isPopoverOpen: false,
            });
        };
        this.state = {
            isPopoverOpen: false,
            items: [],
        };
    }
    render() {
        const button = (react_1.default.createElement(eui_1.EuiButton, { size: "s", iconType: "arrowDown", iconSide: "right", onClick: this.onButtonClick, disabled: this.props.disabled }, this.props.name));
        return (react_1.default.createElement(eui_1.EuiPopover, { id: "contentPanel", button: button, isOpen: this.state.isPopoverOpen, closePopover: this.closePopover, panelPaddingSize: "none", anchorPosition: "downLeft" },
            react_1.default.createElement(eui_1.EuiContextMenuPanel, null,
                react_1.default.createElement(eui_1.EuiFlexGroup, { direction: "column", gutterSize: "xs", style: { margin: 10 } },
                    !this.props.items && react_1.default.createElement(eui_1.EuiLoadingSpinner, { size: "l" }),
                    this.props.items && this.props.items.length === 0 && (react_1.default.createElement(eui_1.EuiFlexItem, null,
                        react_1.default.createElement(eui_1.EuiFlexGroup, { gutterSize: "xs" },
                            react_1.default.createElement(eui_1.EuiFlexItem, null, "No options avaliable")))),
                    this.props.items &&
                        this.props.items.map((tag) => (react_1.default.createElement(eui_1.EuiFlexItem, { key: `${tag.id}` },
                            react_1.default.createElement(eui_1.EuiFlexGroup, { gutterSize: "xs" },
                                react_1.default.createElement(eui_1.EuiFlexItem, null,
                                    react_1.default.createElement(tag_badge_1.TagBadge, { maxIdRenderSize: table_1.TABLE_CONFIG.TRUNCATE_TAG_LENGTH_SMALL, onClick: () => this.props.actionHandler(index_1.AssignmentActionType.Assign, tag.id), onClickAriaLabel: tag.id, tag: tag }))))))))));
    }
}
exports.TagBadgeList = TagBadgeList;

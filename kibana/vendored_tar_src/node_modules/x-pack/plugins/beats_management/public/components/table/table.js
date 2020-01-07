"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const i18n_1 = require("@kbn/i18n");
const react_1 = tslib_1.__importDefault(require("react"));
const styled_components_1 = tslib_1.__importDefault(require("styled-components"));
const constants_1 = require("../../../common/constants");
const index_1 = require("../autocomplete_field/index");
const option_control_1 = require("./controls/option_control");
var AssignmentActionType;
(function (AssignmentActionType) {
    AssignmentActionType[AssignmentActionType["Add"] = 0] = "Add";
    AssignmentActionType[AssignmentActionType["Assign"] = 1] = "Assign";
    AssignmentActionType[AssignmentActionType["Delete"] = 2] = "Delete";
    AssignmentActionType[AssignmentActionType["Edit"] = 3] = "Edit";
    AssignmentActionType[AssignmentActionType["Reload"] = 4] = "Reload";
    AssignmentActionType[AssignmentActionType["Search"] = 5] = "Search";
})(AssignmentActionType = exports.AssignmentActionType || (exports.AssignmentActionType = {}));
const TableContainer = styled_components_1.default.div `
  padding: 16px;
`;
class Table extends react_1.default.Component {
    constructor(props) {
        super(props);
        this.resetSelection = () => {
            this.setSelection([]);
        };
        this.setSelection = (selection) => {
            this.setState({
                selection,
            });
        };
        this.actionHandler = (action, payload) => {
            if (this.props.actionHandler) {
                this.props.actionHandler(action, payload);
            }
        };
        this.onTableChange = (page = { index: 0, size: 50 }) => {
            if (this.props.onTableChange) {
                this.props.onTableChange(page.index, page.size);
            }
            this.setState({
                pageIndex: page.index,
            });
        };
        this.state = {
            selection: [],
            pageIndex: 0,
        };
    }
    render() {
        const { actionData, actions, hideTableControls, items, kueryBarProps, type } = this.props;
        const pagination = {
            pageIndex: this.state.pageIndex,
            pageSize: constants_1.TABLE_CONFIG.INITIAL_ROW_SIZE,
            pageSizeOptions: constants_1.TABLE_CONFIG.PAGE_SIZE_OPTIONS,
        };
        const selectionOptions = hideTableControls
            ? null
            : {
                onSelectionChange: this.setSelection,
                selectable: () => true,
                selectableMessage: () => i18n_1.i18n.translate('xpack.beatsManagement.table.selectThisBeatTooltip', {
                    defaultMessage: 'Select this beat',
                }),
                selection: this.state.selection,
            };
        return (react_1.default.createElement(TableContainer, null,
            react_1.default.createElement(eui_1.EuiFlexGroup, { alignItems: "center", justifyContent: "spaceBetween" },
                actions &&
                    actions.map(action => (react_1.default.createElement(eui_1.EuiFlexItem, { grow: false, key: action.name },
                        react_1.default.createElement(option_control_1.OptionControl, Object.assign({}, action, { actionData: actionData, actionHandler: this.actionHandler, disabled: this.state.selection.length === 0 }))))),
                kueryBarProps && (react_1.default.createElement(eui_1.EuiFlexItem, null,
                    react_1.default.createElement(index_1.AutocompleteField, Object.assign({}, kueryBarProps, { placeholder: i18n_1.i18n.translate('xpack.beatsManagement.table.filterResultsPlaceholder', {
                            defaultMessage: 'Filter results',
                        }) }))))),
            react_1.default.createElement(eui_1.EuiSpacer, { size: "m" }),
            react_1.default.createElement(eui_1.EuiBasicTable, { items: items, itemId: "id", isSelectable: true, selection: selectionOptions, columns: type.columnDefinitions, pagination: { ...pagination, totalItemCount: items.length }, onChange: this.onTableChange })));
    }
}
exports.Table = Table;

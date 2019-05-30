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
const react_1 = require("@kbn/i18n/react");
require("brace/mode/yaml");
require("brace/theme/github");
const react_2 = tslib_1.__importDefault(require("react"));
const config_list_1 = require("../config_list");
const table_1 = require("../table");
const config_view_1 = require("./config_view");
const tag_badge_1 = require("./tag_badge");
class TagEdit extends react_2.default.PureComponent {
    constructor(props) {
        super(props);
        this.getNameError = (name) => {
            if (name && name !== '' && name.search(/^[a-zA-Z0-9-]+$/) === -1) {
                return i18n_1.i18n.translate('xpack.beatsManagement.tag.tagName.validationErrorMessage', {
                    defaultMessage: 'Tag name must consist of letters, numbers, and dashes only',
                });
            }
            else {
                return false;
            }
        };
        this.handleAssignmentActions = (action) => {
            switch (action) {
                case table_1.AssignmentActionType.Delete:
                    const { selection } = this.state.tableRef.current.state;
                    if (this.props.onDetachBeat) {
                        this.props.onDetachBeat(selection.map((beat) => beat.id));
                    }
            }
        };
        this.updateTag = (key, value) => value !== undefined
            ? this.props.onTagChange(key, value)
            : (e) => this.props.onTagChange(key, e.target ? e.target.value : e);
        this.state = {
            showFlyout: false,
            tableRef: react_2.default.createRef(),
        };
    }
    render() {
        const { tag, attachedBeats, configuration_blocks } = this.props;
        return (react_2.default.createElement("div", null,
            react_2.default.createElement(eui_1.EuiFlexGroup, null,
                react_2.default.createElement(eui_1.EuiFlexItem, null,
                    react_2.default.createElement(eui_1.EuiTitle, { size: "xs" },
                        react_2.default.createElement("h3", null,
                            react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.tag.tagDetailsTitle", defaultMessage: "Tag details" }))),
                    react_2.default.createElement(eui_1.EuiText, { color: "subdued" },
                        react_2.default.createElement("p", null,
                            react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.tag.tagDetailsDescription", defaultMessage: "A tag is a group of configuration blocks that you can apply to one or more Beats." }))),
                    react_2.default.createElement("div", null,
                        react_2.default.createElement(tag_badge_1.TagBadge, { tag: tag }))),
                react_2.default.createElement(eui_1.EuiFlexItem, null,
                    react_2.default.createElement(eui_1.EuiForm, null,
                        react_2.default.createElement(eui_1.EuiFormRow, { label: react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.tag.tagNameLabel", defaultMessage: "Tag Name" }), isInvalid: !!this.getNameError(tag.name), error: this.getNameError(tag.name) || undefined },
                            react_2.default.createElement(eui_1.EuiFieldText, { name: "name", isInvalid: !!this.getNameError(tag.name), onChange: this.updateTag('name'), value: tag.name, placeholder: i18n_1.i18n.translate('xpack.beatsManagement.tag.tagNamePlaceholder', {
                                    defaultMessage: 'Tag name (required)',
                                }) })),
                        react_2.default.createElement(eui_1.EuiFormRow, { label: i18n_1.i18n.translate('xpack.beatsManagement.tag.tagColorLabel', {
                                defaultMessage: 'Tag Color',
                            }) },
                            react_2.default.createElement(eui_1.EuiColorPicker, { color: tag.color, onChange: this.updateTag('color') }))))),
            react_2.default.createElement(eui_1.EuiSpacer, null),
            react_2.default.createElement(eui_1.EuiHorizontalRule, null),
            react_2.default.createElement(eui_1.EuiFlexGroup, { alignItems: "stretch" },
                react_2.default.createElement(eui_1.EuiFlexItem, null,
                    react_2.default.createElement(eui_1.EuiTitle, { size: "xs" },
                        react_2.default.createElement("h3", null,
                            react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.tag.tagConfigurationsTitle", defaultMessage: "Configuration blocks" }))),
                    react_2.default.createElement(eui_1.EuiText, { color: "subdued" },
                        react_2.default.createElement("p", null,
                            react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.tag.tagConfigurationsDescription", defaultMessage: "A tag can have configuration blocks for different types of Beats. For example, a tag\n                  can have two Metricbeat configuration blocks and one Filebeat input configuration block." })))),
                react_2.default.createElement(eui_1.EuiFlexItem, null,
                    react_2.default.createElement("div", null,
                        react_2.default.createElement(config_list_1.ConfigList, { onTableChange: this.props.onConfigListChange, configs: configuration_blocks, onConfigClick: (action, block) => {
                                if (action === 'delete') {
                                    this.props.onConfigRemoved(block);
                                }
                                else {
                                    this.setState({
                                        showFlyout: true,
                                        selectedConfig: block,
                                    });
                                }
                            } }),
                        react_2.default.createElement("br", null),
                        react_2.default.createElement(eui_1.EuiButton, { onClick: () => {
                                this.setState({ showFlyout: true });
                            } },
                            react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.tag.addConfigurationButtonLabel", defaultMessage: "Add configuration block" }))))),
            react_2.default.createElement(eui_1.EuiSpacer, null),
            attachedBeats && (react_2.default.createElement("div", null,
                react_2.default.createElement(eui_1.EuiHorizontalRule, null),
                react_2.default.createElement(eui_1.EuiTitle, { size: "xs" },
                    react_2.default.createElement("h3", null,
                        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.tag.beatsAssignedToTagTitle", defaultMessage: "Beats with this tag" }))),
                react_2.default.createElement(table_1.Table, { actions: table_1.tagConfigActions, actionHandler: this.handleAssignmentActions, items: attachedBeats, ref: this.state.tableRef, type: table_1.BeatsTableType }))),
            this.state.showFlyout && (react_2.default.createElement(config_view_1.ConfigView, { configBlock: this.state.selectedConfig, onClose: () => this.setState({ showFlyout: false, selectedConfig: undefined }), onSave: (config) => {
                    this.setState({ showFlyout: false, selectedConfig: undefined });
                    this.props.onConfigAddOrEdit(config);
                } }))));
    }
}
exports.TagEdit = TagEdit;

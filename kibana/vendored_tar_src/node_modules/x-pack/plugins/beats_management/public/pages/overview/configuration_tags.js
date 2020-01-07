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
const react_2 = tslib_1.__importDefault(require("react"));
const breadcrumb_1 = require("../../components/navigation/breadcrumb");
const table_1 = require("../../components/table");
const action_schema_1 = require("../../components/table/action_schema");
const with_kuery_autocompletion_1 = require("../../containers/with_kuery_autocompletion");
class TagsPageComponent extends react_2.default.PureComponent {
    constructor(props) {
        super(props);
        this.renderActionArea = () => (react_2.default.createElement(eui_1.EuiButton, { size: "s", color: "primary", onClick: async () => {
                this.props.goTo('/tag/create');
            } },
            react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.tags.addTagButtonLabel", defaultMessage: "Add Tag" })));
        this.handleTagsAction = async (action) => {
            const { intl } = this.props;
            switch (action) {
                case table_1.AssignmentActionType.Delete:
                    const success = await this.props.containers.tags.delete(this.getSelectedTags());
                    if (!success) {
                        alert(intl.formatMessage({
                            id: 'xpack.beatsManagement.tags.someTagsMightBeAssignedToBeatsTitle',
                            defaultMessage: 'Some of these tags might be assigned to beats. Please ensure tags being removed are not activly assigned',
                        }));
                    }
                    else {
                        if (this.state.tableRef && this.state.tableRef.current) {
                            this.state.tableRef.current.resetSelection();
                        }
                    }
                    break;
            }
        };
        this.getSelectedTags = () => {
            return this.state.tableRef.current ? this.state.tableRef.current.state.selection : [];
        };
        this.state = {
            tableRef: react_2.default.createRef(),
        };
        props.containers.tags.reload(props.urlState.tagsKBar);
        props.renderAction(this.renderActionArea);
    }
    render() {
        return (react_2.default.createElement(react_2.default.Fragment, null,
            react_2.default.createElement(breadcrumb_1.Breadcrumb, { title: i18n_1.i18n.translate('xpack.beatsManagement.breadcrumb.configurationTags', {
                    defaultMessage: 'Configuration tags',
                }), path: `/overview/configuration_tags` }),
            react_2.default.createElement(with_kuery_autocompletion_1.WithKueryAutocompletion, { libs: this.props.libs, fieldPrefix: "tag" }, autocompleteProps => (react_2.default.createElement(table_1.Table, { kueryBarProps: {
                    ...autocompleteProps,
                    filterQueryDraft: 'false',
                    isValid: this.props.libs.elasticsearch.isKueryValid(this.props.urlState.tagsKBar || ''),
                    onChange: (value) => {
                        this.props.setUrlState({ tagsKBar: value });
                        this.props.containers.tags.reload(value);
                    },
                    onSubmit: () => null,
                    value: this.props.urlState.tagsKBar || '',
                }, actions: action_schema_1.tagListActions, actionHandler: this.handleTagsAction, ref: this.state.tableRef, items: this.props.containers.tags.state.list, type: table_1.TagsTableType })))));
    }
}
exports.TagsPage = react_1.injectI18n(TagsPageComponent);

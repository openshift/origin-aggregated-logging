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
const breadcrumb_1 = require("../../components/navigation/breadcrumb");
const table_1 = require("../../components/table");
class BeatTagsPage extends react_1.default.PureComponent {
    constructor(props) {
        super(props);
        this.tableRef = react_1.default.createRef();
        this.state = {
            notifications: [],
            tags: [],
        };
    }
    componentWillMount() {
        this.updateBeatsData();
    }
    async updateBeatsData() {
        const tags = await this.props.libs.tags.getTagsWithIds(this.props.beat.tags);
        this.setState({
            tags,
        });
    }
    render() {
        const { beat } = this.props;
        return (react_1.default.createElement(react_1.default.Fragment, null,
            react_1.default.createElement(breadcrumb_1.Breadcrumb, { title: i18n_1.i18n.translate('xpack.beatsManagement.breadcrumb.beatTags', {
                    defaultMessage: 'Beat tags for: {beatId}',
                    values: { beatId: beat.id },
                }), path: `/beat/${beat.id}/tags` }),
            react_1.default.createElement(table_1.Table, { hideTableControls: true, items: this.state.tags, ref: this.tableRef, type: table_1.BeatDetailTagsTable }),
            react_1.default.createElement(eui_1.EuiGlobalToastList, { toasts: this.state.notifications, dismissToast: () => this.setState({ notifications: [] }), toastLifeTimeMs: 5000 })));
    }
}
exports.BeatTagsPage = BeatTagsPage;

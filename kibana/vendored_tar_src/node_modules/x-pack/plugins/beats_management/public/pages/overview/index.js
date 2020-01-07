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
const unstated_1 = require("unstated");
const primary_1 = require("../../components/layouts/primary");
const child_routes_1 = require("../../components/navigation/child_routes");
const beats_1 = require("../../containers/beats");
const tags_1 = require("../../containers/tags");
const with_url_state_1 = require("../../containers/with_url_state");
class MainPageComponent extends react_2.default.PureComponent {
    constructor(props) {
        super(props);
        this.onTabClicked = (path) => {
            return () => {
                this.props.goTo(path);
            };
        };
        this.state = {
            loadedBeatsAtLeastOnce: false,
            beats: [],
        };
    }
    render() {
        return (react_2.default.createElement(primary_1.PrimaryLayout, { title: react_2.default.createElement(eui_1.EuiFlexGroup, { alignItems: "center", gutterSize: "m" },
                react_2.default.createElement(eui_1.EuiFlexItem, { grow: false }, 'Beats'),
                react_2.default.createElement(eui_1.EuiFlexItem, { grow: false },
                    react_2.default.createElement(eui_1.EuiBetaBadge, { label: i18n_1.i18n.translate('xpack.beatsManagement.overview.betaBadgeText', {
                            defaultMessage: 'Beta',
                        }) }))), hideBreadcrumbs: this.props.libs.framework.versionGreaterThen('6.7.0') }, (renderAction) => (react_2.default.createElement(unstated_1.Subscribe, { to: [beats_1.BeatsContainer, tags_1.TagsContainer] }, (beats, tags) => (react_2.default.createElement(react_2.default.Fragment, null,
            react_2.default.createElement(eui_1.EuiTabs, null,
                react_2.default.createElement(eui_1.EuiTab, { isSelected: `/overview/enrolled_beats` === this.props.history.location.pathname, onClick: this.onTabClicked(`/overview/enrolled_beats`) },
                    react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.beats.enrolledBeatsTabTitle", defaultMessage: "Enrolled Beats" })),
                react_2.default.createElement(eui_1.EuiTab, { isSelected: `/overview/configuration_tags` === this.props.history.location.pathname, onClick: this.onTabClicked(`/overview/configuration_tags`) },
                    react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.beats.configurationTagsTabTitle", defaultMessage: "Configuration tags" }))),
            react_2.default.createElement(child_routes_1.ChildRoutes, Object.assign({ routes: this.props.routes, renderAction: renderAction }, this.props, { beatsContainer: beats, tagsContainer: tags }))))))));
    }
}
exports.MainPage = with_url_state_1.withUrlState(MainPageComponent);

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const react_1 = require("@kbn/i18n/react");
const moment_1 = tslib_1.__importDefault(require("moment"));
const react_2 = tslib_1.__importDefault(require("react"));
const react_router_dom_1 = require("react-router-dom");
const primary_1 = require("../../components/layouts/primary");
const breadcrumb_1 = require("../../components/navigation/breadcrumb");
const child_routes_1 = require("../../components/navigation/child_routes");
class BeatDetailsPageComponent extends react_2.default.PureComponent {
    constructor(props) {
        super(props);
        this.onSelectedTabChanged = (id) => {
            this.props.history.push({
                pathname: id,
                search: this.props.location.search,
            });
        };
        this.onTabClicked = (path) => {
            return () => {
                this.props.goTo(path);
            };
        };
        this.state = {
            beat: undefined,
            beatId: props.match.params.beatId,
            isLoading: true,
        };
        this.loadBeat();
    }
    renderActionSection(beat) {
        return beat ? (react_2.default.createElement(eui_1.EuiFlexGroup, null,
            react_2.default.createElement(eui_1.EuiFlexItem, { grow: false },
                react_2.default.createElement(eui_1.EuiText, { size: "xs" },
                    react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.beat.actionSectionTypeLabel", defaultMessage: "Type: {beatType}.", values: { beatType: react_2.default.createElement("strong", null, beat.type) } }))),
            react_2.default.createElement(eui_1.EuiFlexItem, { grow: false },
                react_2.default.createElement(eui_1.EuiText, { size: "xs" },
                    react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.beat.actionSectionVersionLabel", defaultMessage: "Version: {beatVersion}.", values: { beatVersion: react_2.default.createElement("strong", null, beat.version) } }))),
            beat.last_updated && (react_2.default.createElement(eui_1.EuiFlexItem, { grow: false },
                react_2.default.createElement(eui_1.EuiText, { size: "xs" },
                    react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.beat.lastConfigUpdateMessage", defaultMessage: "Last Config Update: {lastUpdateTime}.", values: {
                            lastUpdateTime: react_2.default.createElement("strong", null, moment_1.default(beat.last_updated).fromNow()),
                        } })))))) : (react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.beat.beatNotFoundMessage", defaultMessage: "Beat not found" }));
    }
    render() {
        const { intl } = this.props;
        const { beat } = this.state;
        let id;
        let name;
        if (beat) {
            id = beat.id;
            name = beat.name;
        }
        const title = this.state.isLoading
            ? intl.formatMessage({
                id: 'xpack.beatsManagement.beat.loadingTitle',
                defaultMessage: 'Loading',
            })
            : intl.formatMessage({
                id: 'xpack.beatsManagement.beat.beatNameAndIdTitle',
                defaultMessage: 'Beat: {nameOrNoName} (id: {id})',
            }, {
                nameOrNoName: name ||
                    intl.formatHTMLMessage({
                        id: 'xpack.beatsManagement.beat.noNameReceivedFromBeatTitle',
                        defaultMessage: 'No name received from beat',
                    }),
                id,
            });
        return (react_2.default.createElement(primary_1.PrimaryLayout, { title: title, actionSection: this.renderActionSection(beat), hideBreadcrumbs: this.props.libs.framework.versionGreaterThen('6.7.0') },
            react_2.default.createElement(react_2.default.Fragment, null,
                react_2.default.createElement(breadcrumb_1.Breadcrumb, { title: `Enrolled Beats`, path: `/overview/enrolled_beats` }),
                react_2.default.createElement(eui_1.EuiTabs, null,
                    react_2.default.createElement(eui_1.EuiTab, { isSelected: `/beat/${id}/details` === this.props.history.location.pathname, onClick: this.onTabClicked(`/beat/${id}/details`) },
                        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.beat.configTabLabel", defaultMessage: "Config" })),
                    react_2.default.createElement(eui_1.EuiTab, { isSelected: `/beat/${id}/tags` === this.props.history.location.pathname, onClick: this.onTabClicked(`/beat/${id}/tags`) },
                        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.beat.configurationTagsTabLabel", defaultMessage: "Configuration tags" }))),
                !this.state.beat && react_2.default.createElement("div", null, "Beat not found"),
                this.state.beat && (react_2.default.createElement(react_router_dom_1.Switch, null,
                    react_2.default.createElement(child_routes_1.ChildRoutes, Object.assign({ routes: this.props.routes }, this.props, { beat: this.state.beat, useSwitch: false })),
                    id && react_2.default.createElement(react_router_dom_1.Route, { render: () => react_2.default.createElement(react_router_dom_1.Redirect, { to: `/beat/${id}/details` }) }))))));
    }
    async loadBeat() {
        const { intl } = this.props;
        const { beatId } = this.props.match.params;
        let beat;
        try {
            beat = await this.props.libs.beats.get(beatId);
            if (!beat) {
                throw new Error(intl.formatMessage({
                    id: 'xpack.beatsManagement.beat.beatNotFoundErrorMessage',
                    defaultMessage: 'beat not found',
                }));
            }
        }
        catch (e) {
            throw new Error(e);
        }
        this.setState({ beat, isLoading: false });
    }
}
exports.BeatDetailsPage = react_1.injectI18n(BeatDetailsPageComponent);

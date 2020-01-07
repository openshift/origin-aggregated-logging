"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const eui_1 = require("@elastic/eui");
const i18n_1 = require("@kbn/i18n");
const react_1 = require("@kbn/i18n/react");
const react_2 = tslib_1.__importStar(require("react"));
const no_data_1 = require("../../../components/layouts/no_data");
const walkthrough_1 = require("../../../components/layouts/walkthrough");
const child_routes_1 = require("../../../components/navigation/child_routes");
const connected_link_1 = require("../../../components/navigation/connected_link");
class InitialWalkthroughPageComponent extends react_2.Component {
    render() {
        const { intl } = this.props;
        if (this.props.location.pathname === '/walkthrough/initial') {
            return (react_2.default.createElement(no_data_1.NoDataLayout, { title: react_2.default.createElement(eui_1.EuiFlexGroup, { alignItems: "center", gutterSize: "m" },
                    react_2.default.createElement(eui_1.EuiFlexItem, { grow: false }, 'Beats central management '),
                    react_2.default.createElement(eui_1.EuiFlexItem, { grow: false },
                        react_2.default.createElement(eui_1.EuiBetaBadge, { label: i18n_1.i18n.translate('xpack.beatsManagement.walkthrough.initial.betaBadgeText', {
                                defaultMessage: 'Beta',
                            }) }))), actionSection: react_2.default.createElement(connected_link_1.ConnectedLink, { path: "/walkthrough/initial/beat" },
                    react_2.default.createElement(eui_1.EuiButton, { color: "primary", fill: true },
                        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.enrollBeatButtonLabel", defaultMessage: "Enroll Beat" }),
                        ' ')) },
                react_2.default.createElement("p", null,
                    react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.enrollBeat.beatsCentralManagementDescription", defaultMessage: "Manage your configurations in a central location." }))));
        }
        return (react_2.default.createElement(walkthrough_1.WalkthroughLayout, { title: intl.formatMessage({
                id: 'xpack.beatsManagement.enrollBeat.getStartedBeatsCentralManagementTitle',
                defaultMessage: 'Get started with Beats central management',
            }), walkthroughSteps: [
                {
                    id: '/walkthrough/initial/beat',
                    name: intl.formatMessage({
                        id: 'xpack.beatsManagement.enrollBeat.enrollBeatStepLabel',
                        defaultMessage: 'Enroll Beat',
                    }),
                },
                {
                    id: '/walkthrough/initial/tag',
                    name: intl.formatMessage({
                        id: 'xpack.beatsManagement.enrollBeat.createTagStepLabel',
                        defaultMessage: 'Create tag',
                    }),
                },
                {
                    id: '/walkthrough/initial/finish',
                    name: intl.formatMessage({
                        id: 'xpack.beatsManagement.enrollBeat.finishStepLabel',
                        defaultMessage: 'Finish',
                    }),
                },
            ], goTo: () => {
                // FIXME implament goto
            }, activePath: this.props.location.pathname },
            react_2.default.createElement(child_routes_1.ChildRoutes, Object.assign({ routes: this.props.routes }, this.props))));
    }
}
exports.InitialWalkthroughPage = react_1.injectI18n(InitialWalkthroughPageComponent);

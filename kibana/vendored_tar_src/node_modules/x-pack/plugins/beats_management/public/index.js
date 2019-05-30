"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const euiVars = tslib_1.__importStar(require("@elastic/eui/dist/eui_theme_k6_light.json"));
const i18n_1 = require("@kbn/i18n");
const react_1 = tslib_1.__importDefault(require("react"));
const react_router_dom_1 = require("react-router-dom");
const styled_components_1 = require("styled-components");
const i18n_2 = require("ui/i18n");
const unstated_1 = require("unstated");
const constants_1 = require("../common/constants");
const background_1 = require("./components/layouts/background");
const breadcrumb_1 = require("./components/navigation/breadcrumb");
const breadcrumb_2 = require("./components/navigation/breadcrumb/breadcrumb");
const beats_1 = require("./containers/beats");
const tags_1 = require("./containers/tags");
const kibana_1 = require("./lib/compose/kibana");
const router_1 = require("./router");
async function startApp(libs) {
    libs.framework.renderUIAtPath(constants_1.BASE_PATH, react_1.default.createElement(styled_components_1.ThemeProvider, { theme: { eui: euiVars } },
        react_1.default.createElement(i18n_2.I18nContext, null,
            react_1.default.createElement(react_router_dom_1.HashRouter, { basename: "/management/beats_management" },
                react_1.default.createElement(unstated_1.Provider, { inject: [new beats_1.BeatsContainer(libs), new tags_1.TagsContainer(libs)] },
                    react_1.default.createElement(breadcrumb_1.BreadcrumbProvider, { useGlobalBreadcrumbs: libs.framework.versionGreaterThen('6.7.0') },
                        react_1.default.createElement(unstated_1.Subscribe, { to: [beats_1.BeatsContainer, tags_1.TagsContainer] }, (beats, tags) => (react_1.default.createElement(background_1.Background, null,
                            react_1.default.createElement(breadcrumb_2.Breadcrumb, { title: i18n_1.i18n.translate('xpack.beatsManagement.management.breadcrumb', {
                                    defaultMessage: 'Management',
                                }) }),
                            react_1.default.createElement(router_1.AppRouter, { libs: libs, beatsContainer: beats, tagsContainer: tags }))))))))), libs.framework.versionGreaterThen('6.7.0') ? 'management' : 'self');
    await libs.framework.waitUntilFrameworkReady();
    if (libs.framework.licenseIsAtLeast('standard')) {
        libs.framework.registerManagementSection({
            id: 'beats',
            name: i18n_1.i18n.translate('xpack.beatsManagement.centralManagementSectionLabel', {
                defaultMessage: 'Beats',
            }),
            iconName: 'logoBeats',
        });
        libs.framework.registerManagementUI({
            sectionId: 'beats',
            name: i18n_1.i18n.translate('xpack.beatsManagement.centralManagementLinkLabel', {
                defaultMessage: 'Central Management',
            }),
            basePath: constants_1.BASE_PATH,
        });
    }
}
startApp(kibana_1.compose());

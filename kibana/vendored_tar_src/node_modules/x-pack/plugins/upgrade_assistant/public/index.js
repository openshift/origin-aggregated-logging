"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const i18n_1 = require("@kbn/i18n");
const i18n_2 = require("ui/i18n");
// @ts-ignore
const management_1 = require("ui/management");
// @ts-ignore
const modules_1 = require("ui/modules");
// @ts-ignore
const routes_1 = tslib_1.__importDefault(require("ui/routes"));
const version_1 = require("../common/version");
const app_1 = require("./app");
const BASE_PATH = `/management/elasticsearch/upgrade_assistant`;
function startApp() {
    management_1.management.getSection('elasticsearch').register('upgrade_assistant', {
        visible: true,
        display: i18n_1.i18n.translate('xpack.upgradeAssistant.appTitle', {
            defaultMessage: '{version} Upgrade Assistant',
            values: { version: `${version_1.NEXT_MAJOR_VERSION}.0` },
        }),
        order: 100,
        url: `#${BASE_PATH}`,
    });
    modules_1.uiModules.get('kibana').directive('upgradeAssistant', (reactDirective) => {
        return reactDirective(i18n_2.wrapInI18nContext(app_1.RootComponent));
    });
    routes_1.default.when(`${BASE_PATH}/:view?`, {
        template: '<kbn-management-app section="elasticsearch/upgrade_assistant"><upgrade-assistant /></kbn-management-app>',
    });
}
startApp();

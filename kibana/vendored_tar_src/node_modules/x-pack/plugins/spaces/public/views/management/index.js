"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const i18n_1 = require("@kbn/i18n");
require("plugins/spaces/views/management/page_routes");
const react_1 = tslib_1.__importDefault(require("react"));
const management_1 = require("ui/management");
// @ts-ignore
const routes_1 = tslib_1.__importDefault(require("ui/routes"));
const advanced_settings_subtitle_1 = require("./components/advanced_settings_subtitle");
const advanced_settings_title_1 = require("./components/advanced_settings_title");
const MANAGE_SPACES_KEY = 'manage_spaces';
routes_1.default.defaults(/\/management/, {
    resolve: {
        spacesManagementSection(activeSpace) {
            function getKibanaSection() {
                return management_1.management.getSection('kibana');
            }
            function deregisterSpaces() {
                getKibanaSection().deregister(MANAGE_SPACES_KEY);
            }
            function ensureSpagesRegistered() {
                const kibanaSection = getKibanaSection();
                if (!kibanaSection.hasItem(MANAGE_SPACES_KEY)) {
                    kibanaSection.register(MANAGE_SPACES_KEY, {
                        name: 'spacesManagementLink',
                        order: 10,
                        display: i18n_1.i18n.translate('xpack.spaces.displayName', {
                            defaultMessage: 'Spaces',
                        }),
                        url: `#/management/spaces/list`,
                    });
                }
                const PageTitle = () => react_1.default.createElement(advanced_settings_title_1.AdvancedSettingsTitle, { space: activeSpace.space });
                management_1.registerSettingsComponent(management_1.PAGE_TITLE_COMPONENT, PageTitle, true);
                const SubTitle = () => react_1.default.createElement(advanced_settings_subtitle_1.AdvancedSettingsSubtitle, { space: activeSpace.space });
                management_1.registerSettingsComponent(management_1.PAGE_SUBTITLE_COMPONENT, SubTitle, true);
            }
            deregisterSpaces();
            ensureSpagesRegistered();
        },
    },
});

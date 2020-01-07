"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const lodash_1 = require("lodash");
const spaces_manager_1 = require("plugins/spaces/lib/spaces_manager");
// @ts-ignore
const nav_control_html_1 = tslib_1.__importDefault(require("plugins/spaces/views/nav_control/nav_control.html"));
const nav_control_popover_1 = require("plugins/spaces/views/nav_control/nav_control_popover");
// @ts-ignore
const path_1 = require("plugins/xpack_main/services/path");
const user_profile_1 = require("plugins/xpack_main/services/user_profile");
const react_1 = tslib_1.__importDefault(require("react"));
const react_dom_1 = require("react-dom");
const react_dom_2 = tslib_1.__importDefault(require("react-dom"));
const header_global_nav_1 = require("ui/chrome/directives/header_global_nav");
const i18n_1 = require("ui/i18n");
// @ts-ignore
const modules_1 = require("ui/modules");
// @ts-ignore
const chrome_header_nav_controls_1 = require("ui/registry/chrome_header_nav_controls");
// @ts-ignore
const chrome_nav_controls_1 = require("ui/registry/chrome_nav_controls");
const spaces_global_nav_button_1 = require("./components/spaces_global_nav_button");
const spaces_header_nav_button_1 = require("./components/spaces_header_nav_button");
chrome_nav_controls_1.chromeNavControlsRegistry.register(lodash_1.constant({
    name: 'spaces',
    order: 90,
    template: nav_control_html_1.default,
}));
const module = modules_1.uiModules.get('spaces_nav', ['kibana']);
let spacesManager;
module.controller('spacesNavController', ($scope, $http, chrome, Private, activeSpace) => {
    const userProfile = Private(user_profile_1.UserProfileProvider);
    const pathProvider = Private(path_1.PathProvider);
    const domNode = document.getElementById(`spacesNavReactRoot`);
    const spaceSelectorURL = chrome.getInjected('spaceSelectorURL');
    spacesManager = new spaces_manager_1.SpacesManager($http, chrome, spaceSelectorURL);
    let mounted = false;
    $scope.$parent.$watch('isVisible', function isVisibleWatcher(isVisible) {
        if (isVisible && !mounted && !pathProvider.isUnauthenticated()) {
            react_dom_1.render(react_1.default.createElement(i18n_1.I18nContext, null,
                react_1.default.createElement(nav_control_popover_1.NavControlPopover, { spacesManager: spacesManager, activeSpace: activeSpace, userProfile: userProfile, anchorPosition: 'rightCenter', buttonClass: spaces_global_nav_button_1.SpacesGlobalNavButton })), domNode);
            mounted = true;
        }
    });
    // unmount react on controller destroy
    $scope.$on('$destroy', () => {
        if (domNode) {
            react_dom_1.unmountComponentAtNode(domNode);
        }
        mounted = false;
    });
});
module.service('spacesNavState', (activeSpace) => {
    return {
        getActiveSpace: () => {
            return activeSpace.space;
        },
        refreshSpacesList: () => {
            if (spacesManager) {
                spacesManager.requestRefresh();
            }
        },
    };
});
chrome_header_nav_controls_1.chromeHeaderNavControlsRegistry.register(($http, chrome, Private, activeSpace) => ({
    name: 'spaces',
    order: 1000,
    side: header_global_nav_1.NavControlSide.Left,
    render(el) {
        const userProfile = Private(user_profile_1.UserProfileProvider);
        const pathProvider = Private(path_1.PathProvider);
        if (pathProvider.isUnauthenticated()) {
            return;
        }
        const spaceSelectorURL = chrome.getInjected('spaceSelectorURL');
        spacesManager = new spaces_manager_1.SpacesManager($http, chrome, spaceSelectorURL);
        react_dom_2.default.render(react_1.default.createElement(i18n_1.I18nContext, null,
            react_1.default.createElement(nav_control_popover_1.NavControlPopover, { spacesManager: spacesManager, activeSpace: activeSpace, userProfile: userProfile, anchorPosition: "downLeft", buttonClass: spaces_header_nav_button_1.SpacesHeaderNavButton })), el);
    },
}));

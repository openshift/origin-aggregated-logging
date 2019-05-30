"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const moment_timezone_1 = tslib_1.__importDefault(require("moment-timezone"));
// @ts-ignore: implicit any for JS file
const xpack_info_1 = require("plugins/xpack_main/services/xpack_info");
const react_1 = tslib_1.__importDefault(require("react"));
const chrome_1 = tslib_1.__importDefault(require("ui/chrome"));
const share_action_registry_1 = require("ui/share/share_action_registry");
const state_hashing_1 = require("ui/state_management/state_hashing");
const screen_capture_panel_content_1 = require("../components/screen_capture_panel_content");
function reportingProvider(Private, dashboardConfig, i18n) {
    const xpackInfo = Private(xpack_info_1.XPackInfoProvider);
    const getShareActions = ({ objectType, objectId, getUnhashableStates, sharingData, isDirty, onClose, }) => {
        if (!['dashboard', 'visualization'].includes(objectType)) {
            return [];
        }
        // Dashboard only mode does not currently support reporting
        // https://github.com/elastic/kibana/issues/18286
        if (objectType === 'dashboard' && dashboardConfig.getHideWriteControls()) {
            return [];
        }
        const getReportingJobParams = () => {
            // Replace hashes with original RISON values.
            const unhashedUrl = state_hashing_1.unhashUrl(window.location.href, getUnhashableStates());
            const relativeUrl = unhashedUrl.replace(window.location.origin + chrome_1.default.getBasePath(), '');
            const browserTimezone = chrome_1.default.getUiSettingsClient().get('dateFormat:tz') === 'Browser'
                ? moment_timezone_1.default.tz.guess()
                : chrome_1.default.getUiSettingsClient().get('dateFormat:tz');
            return {
                ...sharingData,
                objectType,
                browserTimezone,
                relativeUrls: [relativeUrl],
            };
        };
        const getPngJobParams = () => {
            // Replace hashes with original RISON values.
            const unhashedUrl = state_hashing_1.unhashUrl(window.location.href, getUnhashableStates());
            const relativeUrl = unhashedUrl.replace(window.location.origin + chrome_1.default.getBasePath(), '');
            const browserTimezone = chrome_1.default.getUiSettingsClient().get('dateFormat:tz') === 'Browser'
                ? moment_timezone_1.default.tz.guess()
                : chrome_1.default.getUiSettingsClient().get('dateFormat:tz');
            return {
                ...sharingData,
                objectType,
                browserTimezone,
                relativeUrl,
            };
        };
        const shareActions = [];
        if (xpackInfo.get('features.reporting.printablePdf.showLinks', false)) {
            const panelTitle = i18n('xpack.reporting.shareContextMenu.pdfReportsButtonLabel', {
                defaultMessage: 'PDF Reports',
            });
            shareActions.push({
                shareMenuItem: {
                    name: panelTitle,
                    icon: 'document',
                    toolTipContent: xpackInfo.get('features.reporting.printablePdf.message'),
                    disabled: !xpackInfo.get('features.reporting.printablePdf.enableLinks', false)
                        ? true
                        : false,
                    ['data-test-subj']: 'pdfReportMenuItem',
                    sortOrder: 10,
                },
                panel: {
                    title: panelTitle,
                    content: (react_1.default.createElement(screen_capture_panel_content_1.ScreenCapturePanelContent, { reportType: "printablePdf", objectType: objectType, objectId: objectId, getJobParams: getReportingJobParams, isDirty: isDirty, onClose: onClose })),
                },
            });
        }
        if (xpackInfo.get('features.reporting.png.showLinks', false)) {
            const panelTitle = 'PNG Reports';
            shareActions.push({
                shareMenuItem: {
                    name: panelTitle,
                    icon: 'document',
                    toolTipContent: xpackInfo.get('features.reporting.png.message'),
                    disabled: !xpackInfo.get('features.reporting.png.enableLinks', false) ? true : false,
                    ['data-test-subj']: 'pngReportMenuItem',
                    sortOrder: 10,
                },
                panel: {
                    title: panelTitle,
                    content: (react_1.default.createElement(screen_capture_panel_content_1.ScreenCapturePanelContent, { reportType: "png", objectType: objectType, objectId: objectId, getJobParams: getPngJobParams, isDirty: isDirty, onClose: onClose })),
                },
            });
        }
        return shareActions;
    };
    return {
        id: 'screenCaptureReports',
        getShareActions,
    };
}
share_action_registry_1.ShareContextMenuExtensionsRegistryProvider.register(reportingProvider);

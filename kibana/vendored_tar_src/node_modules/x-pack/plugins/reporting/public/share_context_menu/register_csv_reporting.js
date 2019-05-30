"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
// @ts-ignore: implicit any for JS file
const xpack_info_1 = require("plugins/xpack_main/services/xpack_info");
const react_1 = tslib_1.__importDefault(require("react"));
const share_action_registry_1 = require("ui/share/share_action_registry");
const reporting_panel_content_1 = require("../components/reporting_panel_content");
function reportingProvider(Private, i18n) {
    const xpackInfo = Private(xpack_info_1.XPackInfoProvider);
    const getShareActions = ({ objectType, objectId, sharingData, isDirty, onClose, }) => {
        if ('search' !== objectType) {
            return [];
        }
        const getJobParams = () => {
            return {
                ...sharingData,
                type: objectType,
            };
        };
        const shareActions = [];
        if (xpackInfo.get('features.reporting.csv.showLinks', false)) {
            const panelTitle = i18n('xpack.reporting.shareContextMenu.csvReportsButtonLabel', {
                defaultMessage: 'CSV Reports',
            });
            shareActions.push({
                shareMenuItem: {
                    name: panelTitle,
                    icon: 'document',
                    toolTipContent: xpackInfo.get('features.reporting.csv.message'),
                    disabled: !xpackInfo.get('features.reporting.csv.enableLinks', false) ? true : false,
                    ['data-test-subj']: 'csvReportMenuItem',
                },
                panel: {
                    title: panelTitle,
                    content: (react_1.default.createElement(reporting_panel_content_1.ReportingPanelContent, { reportType: "csv", layoutId: undefined, objectType: objectType, objectId: objectId, getJobParams: getJobParams, isDirty: isDirty, onClose: onClose })),
                },
            });
        }
        return shareActions;
    };
    return {
        id: 'csvReports',
        getShareActions,
    };
}
share_action_registry_1.ShareContextMenuExtensionsRegistryProvider.register(reportingProvider);

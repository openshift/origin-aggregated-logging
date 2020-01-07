"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * React component for listing pairs of information about the detector for which
 * rules are being edited.
 */
const react_1 = tslib_1.__importDefault(require("react"));
const eui_1 = require("@elastic/eui");
const react_2 = require("@kbn/i18n/react");
const date_utils_1 = require("../../../util/date_utils");
exports.AnnotationDescriptionList = react_2.injectI18n(({ annotation, intl }) => {
    const listItems = [
        {
            title: intl.formatMessage({
                id: 'xpack.ml.timeSeriesExplorer.annotationDescriptionList.jobIdTitle',
                defaultMessage: 'Job ID',
            }),
            description: annotation.job_id,
        },
        {
            title: intl.formatMessage({
                id: 'xpack.ml.timeSeriesExplorer.annotationDescriptionList.startTitle',
                defaultMessage: 'Start',
            }),
            description: date_utils_1.formatHumanReadableDateTimeSeconds(annotation.timestamp),
        },
    ];
    if (annotation.end_timestamp !== undefined) {
        listItems.push({
            title: intl.formatMessage({
                id: 'xpack.ml.timeSeriesExplorer.annotationDescriptionList.endTitle',
                defaultMessage: 'End',
            }),
            description: date_utils_1.formatHumanReadableDateTimeSeconds(annotation.end_timestamp),
        });
    }
    if (annotation.create_time !== undefined && annotation.modified_time !== undefined) {
        listItems.push({
            title: intl.formatMessage({
                id: 'xpack.ml.timeSeriesExplorer.annotationDescriptionList.createdTitle',
                defaultMessage: 'Created',
            }),
            description: date_utils_1.formatHumanReadableDateTimeSeconds(annotation.create_time),
        });
        listItems.push({
            title: intl.formatMessage({
                id: 'xpack.ml.timeSeriesExplorer.annotationDescriptionList.createdByTitle',
                defaultMessage: 'Created by',
            }),
            description: annotation.create_username,
        });
        listItems.push({
            title: intl.formatMessage({
                id: 'xpack.ml.timeSeriesExplorer.annotationDescriptionList.lastModifiedTitle',
                defaultMessage: 'Last modified',
            }),
            description: date_utils_1.formatHumanReadableDateTimeSeconds(annotation.modified_time),
        });
        listItems.push({
            title: intl.formatMessage({
                id: 'xpack.ml.timeSeriesExplorer.annotationDescriptionList.modifiedByTitle',
                defaultMessage: 'Modified by',
            }),
            description: annotation.modified_username,
        });
    }
    return (react_1.default.createElement(eui_1.EuiDescriptionList, { className: "ml-annotation-description-list", type: "column", listItems: listItems }));
});

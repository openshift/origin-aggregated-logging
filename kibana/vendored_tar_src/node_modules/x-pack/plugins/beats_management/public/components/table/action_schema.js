"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const i18n_1 = require("@kbn/i18n");
const table_1 = require("./table");
var ActionComponentType;
(function (ActionComponentType) {
    ActionComponentType[ActionComponentType["Action"] = 0] = "Action";
    ActionComponentType[ActionComponentType["Popover"] = 1] = "Popover";
    ActionComponentType[ActionComponentType["SelectionCount"] = 2] = "SelectionCount";
    ActionComponentType[ActionComponentType["TagBadgeList"] = 3] = "TagBadgeList";
})(ActionComponentType = exports.ActionComponentType || (exports.ActionComponentType = {}));
exports.beatsListActions = [
    {
        grow: false,
        name: i18n_1.i18n.translate('xpack.beatsManagement.beatsListAssignmentOptions.unenrollButtonLabel', {
            defaultMessage: 'Unenroll selected',
        }),
        showWarning: true,
        type: ActionComponentType.Action,
        warningHeading: i18n_1.i18n.translate('xpack.beatsManagement.beatsListAssignmentOptions.unenrollBeatsWarninigTitle', { defaultMessage: 'Unenroll selected beats?' }),
        warningMessage: i18n_1.i18n.translate('xpack.beatsManagement.beatsListAssignmentOptions.unenrollBeatsWarninigMessage', { defaultMessage: 'The selected Beats will no longer use central management' }),
        action: table_1.AssignmentActionType.Delete,
        danger: true,
    },
    {
        name: i18n_1.i18n.translate('xpack.beatsManagement.beatsListAssignmentOptions.setTagsButtonLabel', {
            defaultMessage: 'Set tags',
        }),
        grow: false,
        type: ActionComponentType.TagBadgeList,
        actionDataKey: 'tags',
        lazyLoad: true,
    },
];
exports.tagListActions = [
    {
        danger: true,
        grow: false,
        name: i18n_1.i18n.translate('xpack.beatsManagement.tagListAssignmentOptions.removeTagsButtonLabel', {
            defaultMessage: 'Remove selected',
        }),
        type: ActionComponentType.Action,
        showWarning: true,
        warningHeading: i18n_1.i18n.translate('xpack.beatsManagement.tagListAssignmentOptions.removeTagsWarninigTitle', { defaultMessage: 'Remove tag(s)' }),
        warningMessage: i18n_1.i18n.translate('xpack.beatsManagement.tagListAssignmentOptions.removeTagWarninigMessage', { defaultMessage: 'Remove the tag?' }),
        action: table_1.AssignmentActionType.Delete,
    },
];
exports.tagConfigActions = [
    {
        danger: true,
        grow: false,
        name: i18n_1.i18n.translate('xpack.beatsManagement.tagConfigAssignmentOptions.removeTagsButtonLabel', {
            defaultMessage: 'Remove tag(s)',
        }),
        type: ActionComponentType.Action,
        showWarning: true,
        warningHeading: i18n_1.i18n.translate('xpack.beatsManagement.tagConfigAssignmentOptions.removeTagsWarninigTitle', { defaultMessage: 'Remove tag(s)' }),
        warningMessage: i18n_1.i18n.translate('xpack.beatsManagement.tagConfigAssignmentOptions.removeTagsWarninigMessage', { defaultMessage: 'Remove the tag from the selected beat(s)?' }),
        action: table_1.AssignmentActionType.Delete,
    },
];

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const i18n_1 = require("@kbn/i18n");
const lodash_1 = require("lodash");
const moment_1 = tslib_1.__importDefault(require("moment"));
const react_1 = tslib_1.__importDefault(require("react"));
const connected_link_1 = require("../navigation/connected_link");
const tag_1 = require("../tag");
const dynamicStatuses = {
    STARTING: {
        color: 'success',
        status: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.startingStatusLabel', {
            defaultMessage: 'Starting',
        }),
        details: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configStatus.startingTooltip', {
            defaultMessage: 'This Beat is starting.',
        }),
    },
    IN_PROGRESS: {
        color: 'warning',
        status: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.updatingStatusLabel', {
            defaultMessage: 'Updating',
        }),
        details: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configStatus.progressTooltip', {
            defaultMessage: 'This Beat is currently reloading config from CM.',
        }),
    },
    RUNNING: {
        color: 'success',
        status: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.runningStatusLabel', {
            defaultMessage: 'Running',
        }),
        details: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configStatus.runningTooltip', {
            defaultMessage: 'This Beat is running without issues.',
        }),
    },
    CONFIG: {
        color: 'danger',
        status: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configErrorStatusLabel', {
            defaultMessage: 'Config error',
        }),
    },
    FAILED: {
        color: 'danger',
        status: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.failedStatusLabel', {
            defaultMessage: 'Error',
        }),
        details: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configStatus.errorTooltip', {
            defaultMessage: 'There is an error on this beat, please check the logs for this host.',
        }),
    },
    STOPPED: {
        color: 'danger',
        status: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.stoppedStatusLabel', {
            defaultMessage: 'stopped',
        }),
        details: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configStatus.errorTooltip', {
            defaultMessage: 'There is an error on this beat, please check the logs for this host.',
        }),
    },
};
exports.BeatsTableType = {
    itemType: 'Beats',
    columnDefinitions: [
        {
            field: 'name',
            name: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.beatNameTitle', {
                defaultMessage: 'Beat name',
            }),
            render: (name, beat) => (react_1.default.createElement(connected_link_1.ConnectedLink, { path: `/beat/${beat.id}/details` }, name)),
            sortable: true,
        },
        {
            field: 'type',
            name: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.typeTitle', {
                defaultMessage: 'Type',
            }),
            sortable: true,
        },
        {
            field: 'full_tags',
            name: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.tagsTitle', {
                defaultMessage: 'Tags',
            }),
            render: (value, beat) => (react_1.default.createElement(eui_1.EuiFlexGroup, { wrap: true, responsive: true, gutterSize: "xs" }, (lodash_1.sortBy(beat.tags, 'id') || []).map(tag => (react_1.default.createElement(eui_1.EuiFlexItem, { key: tag.id, grow: false },
                react_1.default.createElement(connected_link_1.ConnectedLink, { path: `/tag/edit/${tag.id}` },
                    react_1.default.createElement(tag_1.TagBadge, { tag: tag }))))))),
            sortable: false,
        },
        {
            field: 'config_status',
            name: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configStatusTitle', {
                defaultMessage: 'Config Status',
            }),
            render: (value, beat) => {
                let color = 'success';
                let statusText = i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configStatus.okLabel', {
                    defaultMessage: 'OK',
                });
                let tooltipText = i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configStatus.okTooltip', {
                    defaultMessage: 'Beat successfully applied latest config',
                });
                if (beat.status && moment_1.default().diff(beat.last_checkin, 'minutes') < 10) {
                    color = dynamicStatuses[beat.status.event.type].color;
                    statusText = dynamicStatuses[beat.status.event.type].status;
                    tooltipText =
                        dynamicStatuses[beat.status.event.type].details || beat.status.event.message;
                }
                else if (!beat.status && moment_1.default().diff(beat.last_checkin, 'minutes') >= 10) {
                    color = 'danger';
                    statusText = i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configStatus.offlineLabel', {
                        defaultMessage: 'Offline',
                    });
                    tooltipText = i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configStatus.noConnectionTooltip', {
                        defaultMessage: 'This Beat has not connected to kibana in over 10min',
                    });
                }
                else if (beat.status && moment_1.default().diff(beat.last_checkin, 'minutes') >= 10) {
                    color = 'subdued';
                    tooltipText = i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configStatus.notStartedTooltip', {
                        defaultMessage: 'This Beat has not yet been started.',
                    });
                    statusText = i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configStatus.notStartedLabel', {
                        defaultMessage: 'Not started',
                    });
                }
                else {
                    color = 'subdued';
                    statusText = i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.configStatus.offlineLabel', {
                        defaultMessage: 'Offline',
                    });
                }
                return (react_1.default.createElement(eui_1.EuiFlexGroup, { wrap: true, responsive: true, gutterSize: "xs" },
                    react_1.default.createElement(eui_1.EuiToolTip, { content: tooltipText },
                        react_1.default.createElement(eui_1.EuiHealth, { color: color }, statusText))));
            },
            sortable: false,
        },
    ],
    controlDefinitions: (data) => ({
        actions: [
            {
                name: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.disenrollSelectedLabel', {
                    defaultMessage: 'Unenroll Selected',
                }),
                action: 'delete',
                danger: true,
            },
        ],
        filters: [
            {
                type: 'field_value_selection',
                field: 'type',
                name: i18n_1.i18n.translate('xpack.beatsManagement.beatsTable.typeLabel', {
                    defaultMessage: 'Type',
                }),
                options: lodash_1.uniq(data.map(({ type }) => ({ value: type })), 'value'),
            },
        ],
    }),
};
exports.TagsTableType = {
    itemType: 'Tags',
    columnDefinitions: [
        {
            field: 'id',
            name: i18n_1.i18n.translate('xpack.beatsManagement.tagsTable.tagNameTitle', {
                defaultMessage: 'Tag name',
            }),
            render: (id, tag) => (react_1.default.createElement(connected_link_1.ConnectedLink, { path: `/tag/edit/${tag.id}` },
                react_1.default.createElement(tag_1.TagBadge, { tag: tag }))),
            sortable: true,
            width: '45%',
        },
        {
            align: 'right',
            field: 'last_updated',
            name: i18n_1.i18n.translate('xpack.beatsManagement.tagsTable.lastUpdateTitle', {
                defaultMessage: 'Last update',
            }),
            render: (lastUpdate) => react_1.default.createElement("div", null, moment_1.default(lastUpdate).fromNow()),
            sortable: true,
        },
    ],
    controlDefinitions: (data) => ({
        actions: [
            {
                name: i18n_1.i18n.translate('xpack.beatsManagement.tagsTable.removeSelectedLabel', {
                    defaultMessage: 'Remove Selected',
                }),
                action: 'delete',
                danger: true,
            },
        ],
        filters: [],
    }),
};
exports.BeatDetailTagsTable = {
    itemType: 'Tags',
    columnDefinitions: [
        {
            field: 'id',
            name: i18n_1.i18n.translate('xpack.beatsManagement.beatTagsTable.tagNameTitle', {
                defaultMessage: 'Tag name',
            }),
            render: (id, tag) => (react_1.default.createElement(connected_link_1.ConnectedLink, { path: `/tag/edit/${tag.id}` },
                react_1.default.createElement(tag_1.TagBadge, { tag: tag }))),
            sortable: true,
            width: '55%',
        },
        {
            align: 'right',
            field: 'last_updated',
            name: i18n_1.i18n.translate('xpack.beatsManagement.beatTagsTable.lastUpdateTitle', {
                defaultMessage: 'Last update',
            }),
            render: (lastUpdate) => react_1.default.createElement("span", null, moment_1.default(lastUpdate).fromNow()),
            sortable: true,
        },
    ],
    controlDefinitions: (data) => ({
        actions: [],
        filters: [],
        primaryActions: [
            {
                name: i18n_1.i18n.translate('xpack.beatsManagement.beatTagsTable.addTagLabel', {
                    defaultMessage: 'Add Tag',
                }),
                action: 'add',
                danger: false,
            },
            {
                name: i18n_1.i18n.translate('xpack.beatsManagement.beatTagsTable.removeSelectedLabel', {
                    defaultMessage: 'Remove Selected',
                }),
                action: 'remove',
                danger: true,
            },
        ],
    }),
};

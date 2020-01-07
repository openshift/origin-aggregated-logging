"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const react_1 = require("@kbn/i18n/react");
const react_2 = tslib_1.__importDefault(require("react"));
exports.ViewSwitcher = react_1.injectI18n(({ view, onChange, intl }) => {
    const buttons = [
        {
            id: 'map',
            label: intl.formatMessage({
                id: 'xpack.infra.viewSwitcher.mapViewLabel',
                defaultMessage: 'Map View',
            }),
            iconType: 'apps',
        },
        {
            id: 'table',
            label: intl.formatMessage({
                id: 'xpack.infra.viewSwitcher.tableViewLabel',
                defaultMessage: 'Table View',
            }),
            iconType: 'editorUnorderedList',
        },
    ];
    return (react_2.default.createElement(eui_1.EuiButtonGroup, { legend: intl.formatMessage({
            id: 'xpack.infra.viewSwitcher.lenged',
            defaultMessage: 'Switch between table and map view',
        }), options: buttons, color: "primary", idSelected: view, onChange: onChange }));
});

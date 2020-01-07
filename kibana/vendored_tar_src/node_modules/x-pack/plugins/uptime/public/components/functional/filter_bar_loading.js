"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
// @ts-ignore No typings for EuiSearchBar
const eui_1 = require("@elastic/eui");
const i18n_1 = require("@kbn/i18n");
const react_1 = tslib_1.__importDefault(require("react"));
const searchBox = {
    placeholder: i18n_1.i18n.translate('xpack.uptime.filterBar.loadingMessage', {
        defaultMessage: 'Loading…',
    }),
};
/**
 * This component provides a visual placeholder while the FilterBar is loading.
 * The onChange prop is required, so we provide an empty function to suppress the warning.
 */
exports.FilterBarLoading = () => (react_1.default.createElement(eui_1.EuiSearchBar, { box: searchBox, onChange: () => {
        /* */
    } }));

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = require("@kbn/i18n/react");
const React = tslib_1.__importStar(require("react"));
const no_data_1 = require("../../components/layouts/no_data");
exports.InvalidLicensePage = react_1.injectI18n(({ intl }) => (React.createElement(no_data_1.NoDataLayout, { title: intl.formatMessage({
        id: 'xpack.beatsManagement.invalidLicenseTitle',
        defaultMessage: 'Expired license',
    }), actionSection: [] },
    React.createElement("p", null,
        React.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.invalidLicenseDescription", defaultMessage: "Your current license is expired. Enrolled Beats will continue to work, but you need a valid\n          license to access the Beats Management UI." })))));

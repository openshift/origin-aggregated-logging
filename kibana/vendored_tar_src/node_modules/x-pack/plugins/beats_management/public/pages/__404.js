"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = require("@kbn/i18n/react");
const react_2 = tslib_1.__importDefault(require("react"));
class NotFoundPage extends react_2.default.PureComponent {
    render() {
        return (react_2.default.createElement("div", null,
            react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.noContentFoundErrorMessage", defaultMessage: "No content found" })));
    }
}
exports.NotFoundPage = NotFoundPage;

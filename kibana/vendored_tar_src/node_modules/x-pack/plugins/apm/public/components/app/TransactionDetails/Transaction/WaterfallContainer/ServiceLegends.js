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
const react_1 = tslib_1.__importDefault(require("react"));
const styled_components_1 = tslib_1.__importDefault(require("styled-components"));
const variables_1 = require("../../../../../style/variables");
// @ts-ignore
const Legend_1 = tslib_1.__importDefault(require("../../../../shared/charts/Legend"));
const Legends = styled_components_1.default.div `
  display: flex;

  > * {
    margin-right: ${variables_1.px(variables_1.unit)};
    &:last-child {
      margin-right: 0;
    }
  }
`;
function ServiceLegends({ serviceColors }) {
    return (react_1.default.createElement(Legends, null,
        react_1.default.createElement(eui_1.EuiTitle, { size: "xxxs" },
            react_1.default.createElement("span", null, i18n_1.i18n.translate('xpack.apm.transactionDetails.servicesTitle', {
                defaultMessage: 'Services'
            }))),
        Object.entries(serviceColors).map(([label, color]) => (react_1.default.createElement(Legend_1.default, { key: color, color: color, text: label })))));
}
exports.ServiceLegends = ServiceLegends;

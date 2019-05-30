"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importDefault(require("react"));
const get_agent_marks_1 = require("./get_agent_marks");
const ServiceLegends_1 = require("./ServiceLegends");
const Waterfall_1 = require("./Waterfall");
function WaterfallContainer({ location, urlParams, transaction, waterfall }) {
    const agentMarks = get_agent_marks_1.getAgentMarks(transaction);
    if (!waterfall) {
        return null;
    }
    return (react_1.default.createElement("div", null,
        react_1.default.createElement(ServiceLegends_1.ServiceLegends, { serviceColors: waterfall.serviceColors }),
        react_1.default.createElement(Waterfall_1.Waterfall, { agentMarks: agentMarks, location: location, serviceColors: waterfall.serviceColors, urlParams: urlParams, waterfall: waterfall })));
}
exports.WaterfallContainer = WaterfallContainer;

"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
var InfraWaffleMapLegendMode;
(function (InfraWaffleMapLegendMode) {
    InfraWaffleMapLegendMode["step"] = "step";
    InfraWaffleMapLegendMode["gradient"] = "gradient";
})(InfraWaffleMapLegendMode = exports.InfraWaffleMapLegendMode || (exports.InfraWaffleMapLegendMode = {}));
var InfraWaffleMapRuleOperator;
(function (InfraWaffleMapRuleOperator) {
    InfraWaffleMapRuleOperator["gt"] = "gt";
    InfraWaffleMapRuleOperator["gte"] = "gte";
    InfraWaffleMapRuleOperator["lt"] = "lt";
    InfraWaffleMapRuleOperator["lte"] = "lte";
    InfraWaffleMapRuleOperator["eq"] = "eq";
})(InfraWaffleMapRuleOperator = exports.InfraWaffleMapRuleOperator || (exports.InfraWaffleMapRuleOperator = {}));
var InfraFormatterType;
(function (InfraFormatterType) {
    InfraFormatterType["number"] = "number";
    InfraFormatterType["abbreviatedNumber"] = "abbreviatedNumber";
    InfraFormatterType["bytes"] = "bytes";
    InfraFormatterType["bits"] = "bits";
    InfraFormatterType["percent"] = "percent";
})(InfraFormatterType = exports.InfraFormatterType || (exports.InfraFormatterType = {}));
var InfraWaffleMapDataFormat;
(function (InfraWaffleMapDataFormat) {
    InfraWaffleMapDataFormat["bytesDecimal"] = "bytesDecimal";
    InfraWaffleMapDataFormat["bytesBinaryIEC"] = "bytesBinaryIEC";
    InfraWaffleMapDataFormat["bytesBinaryJEDEC"] = "bytesBinaryJEDEC";
    InfraWaffleMapDataFormat["bitsDecimal"] = "bitsDecimal";
    InfraWaffleMapDataFormat["bitsBinaryIEC"] = "bitsBinaryIEC";
    InfraWaffleMapDataFormat["bitsBinaryJEDEC"] = "bitsBinaryJEDEC";
    InfraWaffleMapDataFormat["abbreviatedNumber"] = "abbreviatedNumber";
})(InfraWaffleMapDataFormat = exports.InfraWaffleMapDataFormat || (exports.InfraWaffleMapDataFormat = {}));

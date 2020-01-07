"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const lib_1 = require("../../lib/lib");
const number_1 = require("./number");
/**
 * The labels are derived from these two Wikipedia articles.
 * https://en.wikipedia.org/wiki/Kilobit
 * https://en.wikipedia.org/wiki/Kilobyte
 */
const LABELS = {
    [lib_1.InfraWaffleMapDataFormat.bytesDecimal]: ['B', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
    [lib_1.InfraWaffleMapDataFormat.bytesBinaryIEC]: [
        'b',
        'Kib',
        'Mib',
        'Gib',
        'Tib',
        'Pib',
        'Eib',
        'Zib',
        'Yib',
    ],
    [lib_1.InfraWaffleMapDataFormat.bytesBinaryJEDEC]: ['B', 'KB', 'MB', 'GB'],
    [lib_1.InfraWaffleMapDataFormat.bitsDecimal]: [
        'bit',
        'kbit',
        'Mbit',
        'Gbit',
        'Tbit',
        'Pbit',
        'Ebit',
        'Zbit',
        'Ybit',
    ],
    [lib_1.InfraWaffleMapDataFormat.bitsBinaryIEC]: [
        'bit',
        'Kibit',
        'Mibit',
        'Gibit',
        'Tibit',
        'Pibit',
        'Eibit',
        'Zibit',
        'Yibit',
    ],
    [lib_1.InfraWaffleMapDataFormat.bitsBinaryJEDEC]: ['bit', 'Kbit', 'Mbit', 'Gbit'],
    [lib_1.InfraWaffleMapDataFormat.abbreviatedNumber]: ['', 'K', 'M', 'B', 'T'],
};
const BASES = {
    [lib_1.InfraWaffleMapDataFormat.bytesDecimal]: 1000,
    [lib_1.InfraWaffleMapDataFormat.bytesBinaryIEC]: 1024,
    [lib_1.InfraWaffleMapDataFormat.bytesBinaryJEDEC]: 1024,
    [lib_1.InfraWaffleMapDataFormat.bitsDecimal]: 1000,
    [lib_1.InfraWaffleMapDataFormat.bitsBinaryIEC]: 1024,
    [lib_1.InfraWaffleMapDataFormat.bitsBinaryJEDEC]: 1024,
    [lib_1.InfraWaffleMapDataFormat.abbreviatedNumber]: 1000,
};
exports.createDataFormatter = (format) => (val) => {
    const labels = LABELS[format];
    const base = BASES[format];
    const power = Math.min(Math.floor(Math.log(Math.abs(val)) / Math.log(base)), labels.length - 1);
    if (power < 0) {
        return `${number_1.formatNumber(val)}${labels[0]}`;
    }
    return `${number_1.formatNumber(val / Math.pow(base, power))}${labels[power]}`;
};

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const lodash_1 = require("lodash");
exports.randomEUIColor = (euiVars) => {
    const rgb = lodash_1.sample(Object.keys(euiVars)
        .filter(key => key.startsWith('euiColorVis'))
        .map(key => euiVars[key]));
    const matchedrgb = rgb.match(/^rgba?[\s+]?\([\s+]?(\d+)[\s+]?,[\s+]?(\d+)[\s+]?,[\s+]?(\d+)[\s+]?/i);
    return matchedrgb && matchedrgb.length === 4
        ? '#' +
            ('0' + parseInt(matchedrgb[1], 10).toString(16)).slice(-2) +
            ('0' + parseInt(matchedrgb[2], 10).toString(16)).slice(-2) +
            ('0' + parseInt(matchedrgb[3], 10).toString(16)).slice(-2)
        : '';
};

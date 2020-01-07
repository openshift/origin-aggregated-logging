"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const lodash_1 = require("lodash");
async function getDeprecationLoggingStatus(callWithRequest, req) {
    const response = await callWithRequest(req, 'cluster.getSettings', {
        includeDefaults: true,
    });
    return {
        isEnabled: isDeprecationLoggingEnabled(response),
    };
}
exports.getDeprecationLoggingStatus = getDeprecationLoggingStatus;
async function setDeprecationLogging(callWithRequest, req, isEnabled) {
    const response = await callWithRequest(req, 'cluster.putSettings', {
        body: {
            transient: {
                'logger.deprecation': isEnabled ? 'WARN' : 'ERROR',
            },
        },
    });
    return {
        isEnabled: isDeprecationLoggingEnabled(response),
    };
}
exports.setDeprecationLogging = setDeprecationLogging;
function isDeprecationLoggingEnabled(settings) {
    const deprecationLogLevel = ['default', 'persistent', 'transient'].reduce((currentLogLevel, settingsTier) => lodash_1.get(settings, [settingsTier, 'logger', 'deprecation'], currentLogLevel), 'WARN');
    return ['ALL', 'TRACE', 'DEBUG', 'INFO', 'WARN'].includes(deprecationLogLevel);
}
exports.isDeprecationLoggingEnabled = isDeprecationLoggingEnabled;

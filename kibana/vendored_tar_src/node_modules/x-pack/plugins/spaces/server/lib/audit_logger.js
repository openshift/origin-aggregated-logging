"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class SpacesAuditLogger {
    constructor(auditLogger) {
        this.auditLogger = auditLogger;
    }
    spacesAuthorizationFailure(username, action, spaceIds) {
        this.auditLogger.log('spaces_authorization_failure', `${username} unauthorized to ${action}${spaceIds ? ' ' + spaceIds.join(',') : ''} spaces`, {
            username,
            action,
            spaceIds,
        });
    }
    spacesAuthorizationSuccess(username, action, spaceIds) {
        this.auditLogger.log('spaces_authorization_success', `${username} authorized to ${action}${spaceIds ? ' ' + spaceIds.join(',') : ''} spaces`, {
            username,
            action,
            spaceIds,
        });
    }
}
exports.SpacesAuditLogger = SpacesAuditLogger;

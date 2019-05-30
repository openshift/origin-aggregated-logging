"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
function UserProfileProvider(userProfile) {
    class UserProfileClass {
        constructor(profileData = {}) {
            this.capabilities = {
                ...profileData,
            };
        }
        hasCapability(capability, defaultValue = true) {
            return capability in this.capabilities ? this.capabilities[capability] : defaultValue;
        }
    }
    return new UserProfileClass(userProfile);
}
exports.UserProfileProvider = UserProfileProvider;

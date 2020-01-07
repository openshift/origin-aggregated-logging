"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class TestingFrameworkAdapter {
    constructor(xpackInfo, shieldUser, version) {
        this.xpackInfo = xpackInfo;
        this.shieldUser = shieldUser;
        this.version = version;
        this.setUISettings = (key, value) => {
            this.settings[key] = value;
        };
    }
    get info() {
        if (this.xpackInfo) {
            return this.xpackInfo;
        }
        else {
            throw new Error('framework adapter must have init called before anything else');
        }
    }
    get currentUser() {
        return this.shieldUser;
    }
    // We dont really want to have this, but it's needed to conditionaly render for k7 due to
    // when that data is needed.
    getUISetting(key) {
        return this.settings[key];
    }
    async waitUntilFrameworkReady() {
        return;
    }
    renderUIAtPath(path, component, toController = 'self') {
        throw new Error('not yet implamented');
    }
    registerManagementSection(settings) {
        throw new Error('not yet implamented');
    }
    registerManagementUI(settings) {
        throw new Error('not yet implamented');
    }
}
exports.TestingFrameworkAdapter = TestingFrameworkAdapter;

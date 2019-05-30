"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const i18n_1 = require("@kbn/i18n");
const notify_1 = require("ui/notify");
const events_1 = require("events");
class SpacesManager extends events_1.EventEmitter {
    constructor(httpAgent, chrome, spaceSelectorURL) {
        super();
        this.httpAgent = httpAgent;
        this.baseUrl = chrome.addBasePath(`/api/spaces`);
        this.spaceSelectorURL = spaceSelectorURL;
    }
    async getSpaces() {
        return await this.httpAgent
            .get(`${this.baseUrl}/space`)
            .then((response) => response.data);
    }
    async getSpace(id) {
        return await this.httpAgent.get(`${this.baseUrl}/space/${id}`);
    }
    async createSpace(space) {
        return await this.httpAgent.post(`${this.baseUrl}/space`, space);
    }
    async updateSpace(space) {
        return await this.httpAgent.put(`${this.baseUrl}/space/${space.id}?overwrite=true`, space);
    }
    async deleteSpace(space) {
        return await this.httpAgent.delete(`${this.baseUrl}/space/${space.id}`);
    }
    async changeSelectedSpace(space) {
        return await this.httpAgent
            .post(`${this.baseUrl}/v1/space/${space.id}/select`)
            .then((response) => {
            if (response.data && response.data.location) {
                window.location = response.data.location;
            }
            else {
                this._displayError();
            }
        })
            .catch(() => this._displayError());
    }
    redirectToSpaceSelector() {
        window.location.href = this.spaceSelectorURL;
    }
    async requestRefresh() {
        this.emit('request_refresh');
    }
    _displayError() {
        notify_1.toastNotifications.addDanger({
            title: i18n_1.i18n.translate('xpack.spaces.spacesManager.unableToChangeSpaceWarningTitle', {
                defaultMessage: 'Unable to change your Space',
            }),
            text: i18n_1.i18n.translate('xpack.spaces.spacesManager.unableToChangeSpaceWarningDescription', {
                defaultMessage: 'please try again later',
            }),
        });
    }
}
exports.SpacesManager = SpacesManager;

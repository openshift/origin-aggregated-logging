"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const axios_1 = tslib_1.__importDefault(require("axios"));
const fs_1 = tslib_1.__importDefault(require("fs"));
const path_1 = require("path");
const pkg = JSON.parse(fs_1.default.readFileSync(path_1.resolve(path_1.join(__dirname, '../../../../../../../package.json'))).toString());
let globalAPI;
class NodeAxiosAPIAdapter {
    constructor(username, password, basePath) {
        this.username = username;
        this.password = password;
        this.basePath = basePath;
    }
    async get(url, query) {
        return await this.REST.get(url, query ? { params: query } : {}).then(resp => resp.data);
    }
    async post(url, body) {
        return await this.REST.post(url, body).then(resp => resp.data);
    }
    async delete(url) {
        return await this.REST.delete(url).then(resp => resp.data);
    }
    async put(url, body) {
        return await this.REST.put(url, body).then(resp => resp.data);
    }
    get REST() {
        if (globalAPI) {
            return globalAPI;
        }
        globalAPI = axios_1.default.create({
            baseURL: this.basePath,
            withCredentials: true,
            responseType: 'json',
            timeout: 60 * 10 * 1000,
            auth: {
                username: this.username,
                password: this.password,
            },
            headers: {
                'Access-Control-Allow-Origin': '*',
                Accept: 'application/json',
                'Content-Type': 'application/json',
                'kbn-version': pkg.version,
                'kbn-xsrf': 'xxx',
            },
        });
        // Add a request interceptor
        globalAPI.interceptors.request.use(config => {
            // Do something before request is sent
            return config;
        }, error => {
            // Do something with request error
            return Promise.reject(error);
        });
        // Add a response interceptor
        globalAPI.interceptors.response.use(response => {
            // Do something with response data
            return response;
        }, error => {
            // Do something with response error
            return Promise.reject(JSON.stringify(error.response.data));
        });
        return globalAPI;
    }
}
exports.NodeAxiosAPIAdapter = NodeAxiosAPIAdapter;

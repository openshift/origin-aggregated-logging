"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const chrome_1 = tslib_1.__importDefault(require("ui/chrome"));
const apiBase = chrome_1.default.addBasePath(`/api/security/v1/fields`);
async function getFields($http, query) {
    return await $http
        .get(`${apiBase}/${query}`)
        .then((response) => response.data || []);
}
exports.getFields = getFields;

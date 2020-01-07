"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const t = tslib_1.__importStar(require("io-ts"));
class DateFromStringType extends t.Type {
    constructor() {
        super('DateFromString', (u) => u instanceof Date, (u, c) => {
            const validation = t.string.validate(u, c);
            if (validation.isLeft()) {
                return validation;
            }
            else {
                const s = validation.value;
                const d = new Date(s);
                return isNaN(d.getTime()) ? t.failure(s, c) : t.success(d);
            }
        }, a => a.toISOString());
        // tslint:disable-next-line
        this._tag = 'DateFromISOStringType';
    }
}
exports.DateFromStringType = DateFromStringType;
exports.DateFromString = new DateFromStringType();

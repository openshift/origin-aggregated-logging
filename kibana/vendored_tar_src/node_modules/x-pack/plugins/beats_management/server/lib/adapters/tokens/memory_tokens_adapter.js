"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class MemoryTokensAdapter {
    constructor(tokenDB) {
        this.tokenDB = tokenDB;
    }
    async deleteEnrollmentToken(user, enrollmentToken) {
        const index = this.tokenDB.findIndex(token => token.token === enrollmentToken);
        if (index > -1) {
            this.tokenDB.splice(index, 1);
        }
    }
    async getEnrollmentToken(user, tokenString) {
        return new Promise(resolve => {
            return resolve(this.tokenDB.find(token => token.token === tokenString));
        });
    }
    async insertTokens(user, tokens) {
        tokens.forEach(token => {
            const existingIndex = this.tokenDB.findIndex(t => t.token === token.token);
            if (existingIndex !== -1) {
                this.tokenDB[existingIndex] = token;
            }
            else {
                this.tokenDB.push(token);
            }
        });
        return tokens;
    }
    setDB(tokenDB) {
        this.tokenDB = tokenDB;
    }
}
exports.MemoryTokensAdapter = MemoryTokensAdapter;

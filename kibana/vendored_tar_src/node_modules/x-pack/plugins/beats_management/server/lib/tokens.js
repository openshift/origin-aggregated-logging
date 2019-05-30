"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const crypto_1 = require("crypto");
const jsonwebtoken_1 = require("jsonwebtoken");
const lodash_1 = require("lodash");
const moment_1 = tslib_1.__importDefault(require("moment"));
const RANDOM_TOKEN_1 = 'b48c4bda384a40cb91c6eb9b8849e77f';
const RANDOM_TOKEN_2 = '80a3819e3cd64f4399f1d4886be7a08b';
class CMTokensDomain {
    constructor(adapter, libs) {
        this.adapter = adapter;
        this.framework = libs.framework;
    }
    async getEnrollmentToken(enrollmentToken) {
        const fullToken = await this.adapter.getEnrollmentToken(this.framework.internalUser, enrollmentToken);
        if (!fullToken) {
            return {
                token: null,
                expired: true,
                expires_on: null,
            };
        }
        const { verified, expired } = this.verifyToken(enrollmentToken, fullToken.token || '', false);
        if (!verified) {
            return {
                expired,
                token: null,
                expires_on: null,
            };
        }
        return { ...fullToken, expired };
    }
    async deleteEnrollmentToken(enrollmentToken) {
        return await this.adapter.deleteEnrollmentToken(this.framework.internalUser, enrollmentToken);
    }
    verifyToken(recivedToken, token2, decode = true) {
        let tokenDecoded = true;
        let expired = false;
        if (decode) {
            const enrollmentTokenSecret = this.framework.getSetting('encryptionKey');
            try {
                jsonwebtoken_1.verify(recivedToken, enrollmentTokenSecret);
                tokenDecoded = true;
            }
            catch (err) {
                if (err.name === 'TokenExpiredError') {
                    expired = true;
                }
                tokenDecoded = false;
            }
        }
        if (typeof recivedToken !== 'string' ||
            typeof token2 !== 'string' ||
            recivedToken.length !== token2.length) {
            // This prevents a more subtle timing attack where we know already the tokens aren't going to
            // match but still we don't return fast. Instead we compare two pre-generated random tokens using
            // the same comparison algorithm that we would use to compare two equal-length tokens.
            return {
                expired,
                verified: crypto_1.timingSafeEqual(Buffer.from(RANDOM_TOKEN_1, 'utf8'), Buffer.from(RANDOM_TOKEN_2, 'utf8')) && tokenDecoded,
            };
        }
        return {
            expired,
            verified: crypto_1.timingSafeEqual(Buffer.from(recivedToken, 'utf8'), Buffer.from(token2, 'utf8')) &&
                tokenDecoded,
        };
    }
    generateAccessToken() {
        const enrollmentTokenSecret = this.framework.getSetting('encryptionKey');
        const tokenData = {
            created: moment_1.default().toJSON(),
            randomHash: crypto_1.randomBytes(26).toString(),
        };
        return jsonwebtoken_1.sign(tokenData, enrollmentTokenSecret);
    }
    async createEnrollmentTokens(user, numTokens = 1) {
        const tokens = [];
        const enrollmentTokensTtlInSeconds = this.framework.getSetting('enrollmentTokensTtlInSeconds');
        const enrollmentTokenExpiration = moment_1.default()
            .add(enrollmentTokensTtlInSeconds, 'seconds')
            .toJSON();
        const enrollmentTokenSecret = this.framework.getSetting('encryptionKey');
        while (tokens.length < numTokens) {
            const tokenData = {
                created: moment_1.default().toJSON(),
                expires: enrollmentTokenExpiration,
                randomHash: crypto_1.randomBytes(26).toString(),
            };
            tokens.push({
                expires_on: enrollmentTokenExpiration,
                token: jsonwebtoken_1.sign(tokenData, enrollmentTokenSecret),
            });
        }
        await Promise.all(lodash_1.chunk(tokens, 100).map(tokenChunk => this.adapter.insertTokens(user, tokenChunk)));
        return tokens.map(token => token.token);
    }
}
exports.CMTokensDomain = CMTokensDomain;

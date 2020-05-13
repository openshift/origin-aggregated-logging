"use strict";
/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const crypto_1 = require("crypto");
const util_1 = require("util");
const randomBytesAsync = util_1.promisify(crypto_1.randomBytes);
exports.DEFAULT_CSP_RULES = Object.freeze([
    `script-src 'unsafe-eval' 'self'`,
    'worker-src blob:',
    'child-src blob:',
]);
async function generateCSPNonce() {
    return (await randomBytesAsync(12)).toString('base64');
}
exports.generateCSPNonce = generateCSPNonce;
function createCSPRuleString(rules, nonce) {
    let ruleString = rules.join('; ');
    if (nonce) {
        ruleString = ruleString.replace(/\{nonce\}/g, nonce);
    }
    return ruleString;
}
exports.createCSPRuleString = createCSPRuleString;

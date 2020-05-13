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
const tslib_1 = require("tslib");
const config_schema_1 = require("@kbn/config-schema");
const crypto_1 = tslib_1.__importDefault(require("crypto"));
// `crypto` type definitions doesn't currently include `crypto.constants`, see
// https://github.com/DefinitelyTyped/DefinitelyTyped/blob/fa5baf1733f49cf26228a4e509914572c1b74adf/types/node/v6/index.d.ts#L3412
const cryptoConstants = crypto_1.default.constants;
const protocolMap = new Map([
    ['TLSv1', cryptoConstants.SSL_OP_NO_TLSv1],
    ['TLSv1.1', cryptoConstants.SSL_OP_NO_TLSv1_1],
    ['TLSv1.2', cryptoConstants.SSL_OP_NO_TLSv1_2],
]);
const sslSchema = config_schema_1.schema.object({
    certificate: config_schema_1.schema.maybe(config_schema_1.schema.string()),
    certificateAuthorities: config_schema_1.schema.maybe(config_schema_1.schema.oneOf([config_schema_1.schema.arrayOf(config_schema_1.schema.string()), config_schema_1.schema.string()])),
    cipherSuites: config_schema_1.schema.arrayOf(config_schema_1.schema.string(), {
        defaultValue: cryptoConstants.defaultCoreCipherList.split(':'),
    }),
    enabled: config_schema_1.schema.boolean({
        defaultValue: false,
    }),
    key: config_schema_1.schema.maybe(config_schema_1.schema.string()),
    keyPassphrase: config_schema_1.schema.maybe(config_schema_1.schema.string()),
    redirectHttpFromPort: config_schema_1.schema.maybe(config_schema_1.schema.number()),
    supportedProtocols: config_schema_1.schema.maybe(config_schema_1.schema.arrayOf(config_schema_1.schema.oneOf([
        config_schema_1.schema.literal('TLSv1'),
        config_schema_1.schema.literal('TLSv1.1'),
        config_schema_1.schema.literal('TLSv1.2'),
    ]))),
}, {
    validate: ssl => {
        if (ssl.enabled && (!ssl.key || !ssl.certificate)) {
            return 'must specify [certificate] and [key] when ssl is enabled';
        }
    },
});
class SslConfig {
    /**
     * @internal
     */
    constructor(config) {
        this.enabled = config.enabled;
        this.redirectHttpFromPort = config.redirectHttpFromPort;
        this.key = config.key;
        this.certificate = config.certificate;
        this.certificateAuthorities = this.initCertificateAuthorities(config.certificateAuthorities);
        this.keyPassphrase = config.keyPassphrase;
        this.cipherSuites = config.cipherSuites;
        this.supportedProtocols = config.supportedProtocols;
    }
    /**
     * Options that affect the OpenSSL protocol behavior via numeric bitmask of the SSL_OP_* options from OpenSSL Options.
     */
    getSecureOptions() {
        if (this.supportedProtocols === undefined || this.supportedProtocols.length === 0) {
            return 0;
        }
        const supportedProtocols = this.supportedProtocols;
        return Array.from(protocolMap).reduce((secureOptions, [protocolAlias, secureOption]) => {
            // `secureOption` is the option that turns *off* support for a particular protocol,
            // so if protocol is supported, we should not enable this option.
            // tslint:disable no-bitwise
            return supportedProtocols.includes(protocolAlias)
                ? secureOptions
                : secureOptions | secureOption;
        }, 0);
    }
    initCertificateAuthorities(certificateAuthorities) {
        if (certificateAuthorities === undefined || Array.isArray(certificateAuthorities)) {
            return certificateAuthorities;
        }
        return [certificateAuthorities];
    }
}
/**
 * @internal
 */
SslConfig.schema = sslSchema;
exports.SslConfig = SslConfig;

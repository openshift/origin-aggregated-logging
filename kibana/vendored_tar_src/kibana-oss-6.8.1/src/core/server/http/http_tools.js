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
const fs_1 = require("fs");
const hapi_1 = require("hapi");
const hoek_1 = tslib_1.__importDefault(require("hoek"));
/**
 * Converts Kibana `HttpConfig` into `ServerOptions` that are accepted by the Hapi server.
 */
function getServerOptions(config, { configureTLS = true } = {}) {
    // Note that all connection options configured here should be exactly the same
    // as in the legacy platform server (see `src/server/http/index`). Any change
    // SHOULD BE applied in both places. The only exception is TLS-specific options,
    // that are configured only here.
    const options = {
        host: config.host,
        port: config.port,
        routes: {
            cors: config.cors,
            payload: {
                maxBytes: config.maxPayload.getValueInBytes(),
            },
            validate: {
                failAction: defaultValidationErrorHandler,
                options: {
                    abortEarly: false,
                },
            },
        },
        state: {
            strictHeader: false,
            isHttpOnly: true,
            isSameSite: false,
        },
    };
    if (configureTLS && config.ssl.enabled) {
        const ssl = config.ssl;
        // TODO: Hapi types have a typo in `tls` property type definition: `https.RequestOptions` is used instead of
        // `https.ServerOptions`, and `honorCipherOrder` isn't presented in `https.RequestOptions`.
        const tlsOptions = {
            ca: config.ssl.certificateAuthorities &&
                config.ssl.certificateAuthorities.map(caFilePath => fs_1.readFileSync(caFilePath)),
            cert: fs_1.readFileSync(ssl.certificate),
            ciphers: config.ssl.cipherSuites.join(':'),
            // We use the server's cipher order rather than the client's to prevent the BEAST attack.
            honorCipherOrder: true,
            key: fs_1.readFileSync(ssl.key),
            passphrase: ssl.keyPassphrase,
            secureOptions: ssl.getSecureOptions(),
        };
        options.tls = tlsOptions;
    }
    return options;
}
exports.getServerOptions = getServerOptions;
function createServer(options) {
    const server = new hapi_1.Server(options);
    // Revert to previous 120 seconds keep-alive timeout in Node < 8.
    server.listener.keepAliveTimeout = 120e3;
    server.listener.on('clientError', (err, socket) => {
        if (socket.writable) {
            socket.end(Buffer.from('HTTP/1.1 400 Bad Request\r\n\r\n', 'ascii'));
        }
        else {
            socket.destroy(err);
        }
    });
    return server;
}
exports.createServer = createServer;
/**
 * Used to replicate Hapi v16 and below's validation responses. Should be used in the routes.validate.failAction key.
 */
function defaultValidationErrorHandler(request, h, err) {
    // Newer versions of Joi don't format the key for missing params the same way. This shim
    // provides backwards compatibility. Unfortunately, Joi doesn't export it's own Error class
    // in JS so we have to rely on the `name` key before we can cast it.
    //
    // The Hapi code we're 'overwriting' can be found here:
    //     https://github.com/hapijs/hapi/blob/master/lib/validation.js#L102
    if (err && err.name === 'ValidationError' && err.hasOwnProperty('output')) {
        const validationError = err;
        const validationKeys = [];
        validationError.details.forEach(detail => {
            if (detail.path.length > 0) {
                validationKeys.push(hoek_1.default.escapeHtml(detail.path.join('.')));
            }
            else {
                // If no path, use the value sigil to signal the entire value had an issue.
                validationKeys.push('value');
            }
        });
        validationError.output.payload.validation.keys = validationKeys;
    }
    throw err;
}
exports.defaultValidationErrorHandler = defaultValidationErrorHandler;

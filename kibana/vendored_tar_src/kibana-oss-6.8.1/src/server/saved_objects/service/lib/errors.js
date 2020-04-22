'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.isSavedObjectsClientError = isSavedObjectsClientError;
exports.decorateBadRequestError = decorateBadRequestError;
exports.isBadRequestError = isBadRequestError;
exports.createInvalidVersionError = createInvalidVersionError;
exports.isInvalidVersionError = isInvalidVersionError;
exports.decorateNotAuthorizedError = decorateNotAuthorizedError;
exports.isNotAuthorizedError = isNotAuthorizedError;
exports.decorateForbiddenError = decorateForbiddenError;
exports.isForbiddenError = isForbiddenError;
exports.decorateRequestEntityTooLargeError = decorateRequestEntityTooLargeError;
exports.isRequestEntityTooLargeError = isRequestEntityTooLargeError;
exports.createGenericNotFoundError = createGenericNotFoundError;
exports.isNotFoundError = isNotFoundError;
exports.decorateConflictError = decorateConflictError;
exports.isConflictError = isConflictError;
exports.decorateEsUnavailableError = decorateEsUnavailableError;
exports.isEsUnavailableError = isEsUnavailableError;
exports.createEsAutoCreateIndexError = createEsAutoCreateIndexError;
exports.isEsAutoCreateIndexError = isEsAutoCreateIndexError;
exports.decorateGeneralError = decorateGeneralError;

var _boom = require('boom');

var _boom2 = _interopRequireDefault(_boom);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const code = Symbol('SavedObjectsClientErrorCode'); /*
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

function decorate(error, errorCode, statusCode, message) {
  if (isSavedObjectsClientError(error)) {
    return error;
  }

  const boom = _boom2.default.boomify(error, {
    statusCode,
    message,
    override: false
  });

  boom[code] = errorCode;

  return boom;
}

function isSavedObjectsClientError(error) {
  return error && !!error[code];
}

// 400 - badRequest
const CODE_BAD_REQUEST = 'SavedObjectsClient/badRequest';
function decorateBadRequestError(error, reason) {
  return decorate(error, CODE_BAD_REQUEST, 400, reason);
}
function isBadRequestError(error) {
  return error && error[code] === CODE_BAD_REQUEST;
}

// 400 - invalid version
const CODE_INVALID_VERSION = 'SavedObjectsClient/invalidVersion';
function createInvalidVersionError(versionInput) {
  return decorate(_boom2.default.badRequest(`Invalid version [${versionInput}]`), CODE_INVALID_VERSION, 400);
}
function isInvalidVersionError(error) {
  return error && error[code] === CODE_INVALID_VERSION;
}

// 401 - Not Authorized
const CODE_NOT_AUTHORIZED = 'SavedObjectsClient/notAuthorized';
function decorateNotAuthorizedError(error, reason) {
  return decorate(error, CODE_NOT_AUTHORIZED, 401, reason);
}
function isNotAuthorizedError(error) {
  return error && error[code] === CODE_NOT_AUTHORIZED;
}

// 403 - Forbidden
const CODE_FORBIDDEN = 'SavedObjectsClient/forbidden';
function decorateForbiddenError(error, reason) {
  return decorate(error, CODE_FORBIDDEN, 403, reason);
}
function isForbiddenError(error) {
  return error && error[code] === CODE_FORBIDDEN;
}

// 413 - Request Entity Too Large
const CODE_REQUEST_ENTITY_TOO_LARGE = 'SavedObjectsClient/requestEntityTooLarge';
function decorateRequestEntityTooLargeError(error, reason) {
  return decorate(error, CODE_REQUEST_ENTITY_TOO_LARGE, 413, reason);
}
function isRequestEntityTooLargeError(error) {
  return error && error[code] === CODE_REQUEST_ENTITY_TOO_LARGE;
}

// 404 - Not Found
const CODE_NOT_FOUND = 'SavedObjectsClient/notFound';
function createGenericNotFoundError(type = null, id = null) {
  if (type && id) {
    return decorate(_boom2.default.notFound(`Saved object [${type}/${id}] not found`), CODE_NOT_FOUND, 404);
  }
  return decorate(_boom2.default.notFound(), CODE_NOT_FOUND, 404);
}
function isNotFoundError(error) {
  return error && error[code] === CODE_NOT_FOUND;
}

// 409 - Conflict
const CODE_CONFLICT = 'SavedObjectsClient/conflict';
function decorateConflictError(error, reason) {
  return decorate(error, CODE_CONFLICT, 409, reason);
}
function isConflictError(error) {
  return error && error[code] === CODE_CONFLICT;
}

// 503 - Es Unavailable
const CODE_ES_UNAVAILABLE = 'SavedObjectsClient/esUnavailable';
function decorateEsUnavailableError(error, reason) {
  return decorate(error, CODE_ES_UNAVAILABLE, 503, reason);
}
function isEsUnavailableError(error) {
  return error && error[code] === CODE_ES_UNAVAILABLE;
}

// 503 - Unable to automatically create index because of action.auto_create_index setting
const CODE_ES_AUTO_CREATE_INDEX_ERROR = 'SavedObjectsClient/autoCreateIndex';
function createEsAutoCreateIndexError() {
  const error = _boom2.default.serverUnavailable('Automatic index creation failed');
  error.output.payload.code = 'ES_AUTO_CREATE_INDEX_ERROR';

  return decorate(error, CODE_ES_AUTO_CREATE_INDEX_ERROR, 503);
}
function isEsAutoCreateIndexError(error) {
  return error && error[code] === CODE_ES_AUTO_CREATE_INDEX_ERROR;
}

// 500 - General Error
const CODE_GENERAL_ERROR = 'SavedObjectsClient/generalError';
function decorateGeneralError(error, reason) {
  return decorate(error, CODE_GENERAL_ERROR, 500, reason);
}
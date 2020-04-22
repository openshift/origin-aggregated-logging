'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.decorateEsError = decorateEsError;

var _elasticsearch = require('elasticsearch');

var _elasticsearch2 = _interopRequireDefault(_elasticsearch);

var _lodash = require('lodash');

var _errors = require('./errors');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

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

const {
  ConnectionFault,
  ServiceUnavailable,
  NoConnections,
  RequestTimeout,
  Conflict,
  401: NotAuthorized,
  403: Forbidden,
  413: RequestEntityTooLarge,
  NotFound,
  BadRequest
} = _elasticsearch2.default.errors;

function decorateEsError(error) {
  if (!(error instanceof Error)) {
    throw new Error('Expected an instance of Error');
  }

  const { reason } = (0, _lodash.get)(error, 'body.error', {});
  if (error instanceof ConnectionFault || error instanceof ServiceUnavailable || error instanceof NoConnections || error instanceof RequestTimeout) {
    return (0, _errors.decorateEsUnavailableError)(error, reason);
  }

  if (error instanceof Conflict) {
    return (0, _errors.decorateConflictError)(error, reason);
  }

  if (error instanceof NotAuthorized) {
    return (0, _errors.decorateNotAuthorizedError)(error, reason);
  }

  if (error instanceof Forbidden) {
    return (0, _errors.decorateForbiddenError)(error, reason);
  }

  if (error instanceof RequestEntityTooLarge) {
    return (0, _errors.decorateRequestEntityTooLargeError)(error, reason);
  }

  if (error instanceof NotFound) {
    return (0, _errors.createGenericNotFoundError)();
  }

  if (error instanceof BadRequest) {
    return (0, _errors.decorateBadRequestError)(error, reason);
  }

  return (0, _errors.decorateGeneralError)(error, reason);
}
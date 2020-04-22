'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.registerServerFunctions = registerServerFunctions;

var _boom = require('boom');

var _boom2 = _interopRequireDefault(_boom);

var _common = require('@kbn/interpreter/common');

var _constants = require('../../common/constants');

var _create_handlers = require('../lib/create_handlers');

var _joi = require('joi');

var _joi2 = _interopRequireDefault(_joi);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) { var target = {}; for (var i in obj) { if (keys.indexOf(i) >= 0) continue; if (!Object.prototype.hasOwnProperty.call(obj, i)) continue; target[i] = obj[i]; } return target; } /*
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

/**
 * Register the Canvas function endopints.
 *
 * @param {*} server - The Kibana server
 */
function registerServerFunctions(server) {
  getServerFunctions(server);
  runServerFunctions(server);
}

/**
 * Register the endpoint that executes a batch of functions, and sends the result back as a single response.
 *
 * @param {*} server - The Kibana server
 */
function runServerFunctions(server) {
  server.route({
    method: 'POST',
    path: `${_constants.API_ROUTE}/fns`,
    options: {
      payload: {
        allow: 'application/json',
        maxBytes: 26214400 // 25MB payload limit
      },
      validate: {
        payload: _joi2.default.object({
          functions: _joi2.default.array().items(_joi2.default.object().keys({
            id: _joi2.default.number().required(),
            functionName: _joi2.default.string().required(),
            args: _joi2.default.object().default({}),
            context: _joi2.default.object().allow(null).default({})
          })).required()
        }).required()
      }
    },
    async handler(req) {
      const handlers = await (0, _create_handlers.createHandlers)(req, server);
      const { functions } = req.payload;

      // Process each function individually, and bundle up respones / errors into
      // the format expected by the front-end batcher.
      const results = await Promise.all(functions.map(async (_ref) => {
        let { id } = _ref,
            fnCall = _objectWithoutProperties(_ref, ['id']);

        const result = await runFunction(server, handlers, fnCall).catch(err => {
          if (_boom2.default.isBoom(err)) {
            return { err, statusCode: err.statusCode, message: err.output.payload };
          } else if (err instanceof Error) {
            return { err, statusCode: 500, message: err.message };
          }

          server.log(['interpreter', 'error'], err);
          return { err: 'Internal Server Error', statusCode: 500, message: 'See server logs for details.' };
        });

        if (typeof result === 'undefined') {
          const { functionName } = fnCall;
          return {
            id,
            result: {
              err: `No result from '${functionName}'`,
              statusCode: 500,
              message: `Function '${functionName}' did not return anything`
            }
          };
        }

        return { id, result };
      }));

      return { results };
    }
  });
}

/**
 * Register the endpoint that returns the list of server-only functions.
 * @param {*} server - The Kibana server
 */
function getServerFunctions(server) {
  server.route({
    method: 'GET',
    path: `${_constants.API_ROUTE}/fns`,
    handler() {
      return server.plugins.interpreter.registries().serverFunctions.toJS();
    }
  });
}

/**
 * Run a single Canvas function.
 *
 * @param {*} server - The Kibana server object
 * @param {*} handlers - The Canvas handlers
 * @param {*} fnCall - Describes the function being run `{ functionName, args, context }`
 */
async function runFunction(server, handlers, fnCall) {
  const registries = server.plugins.interpreter.registries();
  const { functionName, args, context } = fnCall;
  const types = registries.types.toJS();
  const { deserialize } = (0, _common.serializeProvider)(types);
  const fnDef = registries.serverFunctions.toJS()[functionName];

  if (!fnDef) {
    throw _boom2.default.notFound(`Function "${functionName}" could not be found.`);
  }

  return fnDef.fn(deserialize(context), args, handlers);
}
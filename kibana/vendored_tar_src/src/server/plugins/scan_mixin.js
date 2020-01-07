'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.scanMixin = scanMixin;

var _rxjs = require('rxjs');

var Rx = _interopRequireWildcard(_rxjs);

var _operators = require('rxjs/operators');

var _plugin_discovery = require('../../plugin_discovery');

var _lib = require('./lib');

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

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

async function scanMixin(kbnServer, server, config) {
  const {
    pack$,
    invalidDirectoryError$,
    invalidPackError$,
    otherError$,
    deprecation$,
    invalidVersionSpec$,
    spec$,
    disabledSpec$
  } = (0, _plugin_discovery.findPluginSpecs)(kbnServer.settings, config);

  const logging$ = Rx.merge(pack$.pipe((0, _operators.tap)(definition => {
    const path = definition.getPath();
    server.logWithMetadata(['plugin', 'debug'], `Found plugin at ${path}`, {
      path
    });
  })), invalidDirectoryError$.pipe((0, _operators.tap)(error => {
    server.logWithMetadata(['plugin', 'warning'], `${error.code}: Unable to scan directory for plugins "${error.path}"`, {
      err: error,
      dir: error.path
    });
  })), invalidPackError$.pipe((0, _operators.tap)(error => {
    server.logWithMetadata(['plugin', 'warning'], `Skipping non-plugin directory at ${error.path}`, {
      path: error.path
    });
  })), otherError$.pipe((0, _operators.tap)(error => {
    // rethrow unhandled errors, which will fail the server
    throw error;
  })), invalidVersionSpec$.pipe((0, _operators.map)(spec => {
    const name = spec.getId();
    const pluginVersion = spec.getExpectedKibanaVersion();
    const kibanaVersion = config.get('pkg.version');
    return `Plugin "${name}" was disabled because it expected Kibana version "${pluginVersion}", and found "${kibanaVersion}".`;
  }), (0, _operators.distinct)(), (0, _operators.tap)(message => {
    server.log(['plugin', 'warning'], message);
  })), deprecation$.pipe((0, _operators.tap)(({ spec, message }) => {
    server.log(['warning', spec.getConfigPrefix(), 'config', 'deprecation'], message);
  })));

  const enabledSpecs$ = spec$.pipe((0, _operators.toArray)(), (0, _operators.tap)(specs => {
    kbnServer.pluginSpecs = specs;
  }));

  const disabledSpecs$ = disabledSpec$.pipe((0, _operators.toArray)(), (0, _operators.tap)(specs => {
    kbnServer.disabledPluginSpecs = specs;
  }));

  // await completion of enabledSpecs$, disabledSpecs$, and logging$
  await Rx.merge(logging$, enabledSpecs$, disabledSpecs$).toPromise();

  kbnServer.plugins = kbnServer.pluginSpecs.map(spec => new _lib.Plugin(kbnServer, spec));
}
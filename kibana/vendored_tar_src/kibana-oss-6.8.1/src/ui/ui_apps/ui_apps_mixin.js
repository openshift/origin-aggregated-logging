'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; /*
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

exports.uiAppsMixin = uiAppsMixin;

var _ui_app = require('./ui_app');

function uiAppsMixin(kbnServer, server) {

  const { uiAppSpecs = [] } = kbnServer.uiExports;
  const existingIds = new Set();
  const appsById = new Map();
  const hiddenAppsById = new Map();

  kbnServer.uiApps = uiAppSpecs.map(spec => {
    const app = new _ui_app.UiApp(kbnServer, spec);
    const id = app.getId();

    if (!existingIds.has(id)) {
      existingIds.add(id);
    } else {
      throw new Error(`Unable to create two apps with the id ${id}.`);
    }

    if (app.isHidden()) {
      hiddenAppsById.set(id, app);
    } else {
      appsById.set(id, app);
    }

    return app;
  });

  server.decorate('server', 'getAllUiApps', () => kbnServer.uiApps.slice(0));
  server.decorate('server', 'getUiAppById', id => appsById.get(id));
  server.decorate('server', 'getHiddenUiAppById', id => hiddenAppsById.get(id));

  const injectedVarProviders = [];
  server.decorate('server', 'injectUiAppVars', (appId, provider) => {
    injectedVarProviders.push({ appId, provider });
  });

  server.decorate('server', 'getInjectedUiAppVars', async appId => {
    return await injectedVarProviders.filter(p => p.appId === appId).reduce(async (acc, { provider }) => _extends({}, (await acc), (await provider(server))), {});
  });
}
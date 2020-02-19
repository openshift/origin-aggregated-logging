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

exports.uiSettingsMixin = uiSettingsMixin;

var _ui_settings_service_factory = require('./ui_settings_service_factory');

var _ui_settings_service_for_request = require('./ui_settings_service_for_request');

var _routes = require('./routes');

function uiSettingsMixin(kbnServer, server) {
  const getDefaults = () => kbnServer.uiExports.uiSettingDefaults;
  const overrides = kbnServer.config.get('uiSettings.overrides');

  server.decorate('server', 'uiSettingsServiceFactory', (options = {}) => {
    return (0, _ui_settings_service_factory.uiSettingsServiceFactory)(server, _extends({
      getDefaults,
      overrides
    }, options));
  });

  server.addMemoizedFactoryToRequest('getUiSettingsService', request => {
    return (0, _ui_settings_service_for_request.getUiSettingsServiceForRequest)(server, request, {
      getDefaults,
      overrides
    });
  });

  server.decorate('server', 'uiSettings', () => {
    throw new Error(`
      server.uiSettings has been removed, see https://github.com/elastic/kibana/pull/12243.
    `);
  });

  server.route(_routes.deleteRoute);
  server.route(_routes.getRoute);
  server.route(_routes.setManyRoute);
  server.route(_routes.setRoute);
}
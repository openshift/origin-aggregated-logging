'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.windowsMetricsSpecProvider = windowsMetricsSpecProvider;

var _i18n = require('@kbn/i18n');

var _tutorial_category = require('../../../common/tutorials/tutorial_category');

var _metricbeat_instructions = require('../../../common/tutorials/metricbeat_instructions');

function windowsMetricsSpecProvider(server, context) {
  const moduleName = 'windows';
  return {
    id: 'windowsMetrics',
    name: _i18n.i18n.translate('kbn.server.tutorials.windowsMetrics.nameTitle', {
      defaultMessage: 'Windows metrics'
    }),
    isBeta: false,
    category: _tutorial_category.TUTORIAL_CATEGORY.METRICS,
    shortDescription: _i18n.i18n.translate('kbn.server.tutorials.windowsMetrics.shortDescription', {
      defaultMessage: 'Fetch internal metrics from Windows.'
    }),
    longDescription: _i18n.i18n.translate('kbn.server.tutorials.windowsMetrics.longDescription', {
      defaultMessage: 'The `windows` Metricbeat module fetches internal metrics from Windows. \
[Learn more]({learnMoreLink}).',
      values: {
        learnMoreLink: '{config.docs.beats.metricbeat}/metricbeat-module-windows.html'
      }
    }),
    euiIconType: 'logoWindows',
    artifacts: {
      application: {
        label: _i18n.i18n.translate('kbn.server.tutorials.windowsMetrics.artifacts.application.label', {
          defaultMessage: 'Discover'
        }),
        path: '/app/kibana#/discover'
      },
      dashboards: [],
      exportedFields: {
        documentationUrl: '{config.docs.beats.metricbeat}/exported-fields-windows.html'
      }
    },
    completionTimeMinutes: 10,
    onPrem: (0, _metricbeat_instructions.onPremInstructions)(moduleName, null, null, null, context),
    elasticCloud: (0, _metricbeat_instructions.cloudInstructions)(moduleName),
    onPremElasticCloud: (0, _metricbeat_instructions.onPremCloudInstructions)(moduleName)
  };
} /*
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
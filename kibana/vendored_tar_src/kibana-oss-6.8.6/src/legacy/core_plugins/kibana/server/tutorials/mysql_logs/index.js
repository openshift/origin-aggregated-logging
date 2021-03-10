'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.mysqlLogsSpecProvider = mysqlLogsSpecProvider;

var _i18n = require('@kbn/i18n');

var _tutorial_category = require('../../../common/tutorials/tutorial_category');

var _filebeat_instructions = require('../../../common/tutorials/filebeat_instructions');

function mysqlLogsSpecProvider(server, context) {
  const moduleName = 'mysql';
  const platforms = ['OSX', 'DEB', 'RPM', 'WINDOWS'];
  return {
    id: 'mysqlLogs',
    name: _i18n.i18n.translate('kbn.server.tutorials.mysqlLogs.nameTitle', {
      defaultMessage: 'MySQL logs'
    }),
    category: _tutorial_category.TUTORIAL_CATEGORY.LOGGING,
    shortDescription: _i18n.i18n.translate('kbn.server.tutorials.mysqlLogs.shortDescription', {
      defaultMessage: 'Collect and parse error and slow logs created by MySQL.'
    }),
    longDescription: _i18n.i18n.translate('kbn.server.tutorials.mysqlLogs.longDescription', {
      defaultMessage: 'The `mysql` Filebeat module parses error and slow logs created by MySQL. \
[Learn more]({learnMoreLink}).',
      values: {
        learnMoreLink: '{config.docs.beats.filebeat}/filebeat-module-mysql.html'
      }
    }),
    euiIconType: 'logoMySQL',
    artifacts: {
      dashboards: [{
        id: 'Filebeat-MySQL-Dashboard',
        linkLabel: _i18n.i18n.translate('kbn.server.tutorials.mysqlLogs.artifacts.dashboards.linkLabel', {
          defaultMessage: 'MySQL logs dashboard'
        }),
        isOverview: true
      }],
      exportedFields: {
        documentationUrl: '{config.docs.beats.filebeat}/exported-fields-mysql.html'
      }
    },
    completionTimeMinutes: 10,
    previewImagePath: '/plugins/kibana/home/tutorial_resources/mysql_logs/screenshot.png',
    onPrem: (0, _filebeat_instructions.onPremInstructions)(moduleName, platforms, context),
    elasticCloud: (0, _filebeat_instructions.cloudInstructions)(moduleName, platforms),
    onPremElasticCloud: (0, _filebeat_instructions.onPremCloudInstructions)(moduleName, platforms)
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
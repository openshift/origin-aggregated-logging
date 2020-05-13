'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.suricataLogsSpecProvider = suricataLogsSpecProvider;

var _i18n = require('@kbn/i18n');

var _tutorial_category = require('../../../common/tutorials/tutorial_category');

var _filebeat_instructions = require('../../../common/tutorials/filebeat_instructions');

function suricataLogsSpecProvider(server, context) {
  const moduleName = 'suricata';
  const platforms = ['OSX', 'DEB', 'RPM', 'WINDOWS'];
  return {
    id: 'suricataLogs',
    name: _i18n.i18n.translate('kbn.server.tutorials.suricataLogs.nameTitle', {
      defaultMessage: 'Suricata logs'
    }),
    category: _tutorial_category.TUTORIAL_CATEGORY.SECURITY,
    shortDescription: _i18n.i18n.translate('kbn.server.tutorials.suricataLogs.shortDescription', {
      defaultMessage: 'Collect the result logs created by Suricata IDS/IPS/NSM.'
    }),
    longDescription: _i18n.i18n.translate('kbn.server.tutorials.suricataLogs.longDescription', {
      defaultMessage: 'The `suricata` Filebeat module collects the logs from the \
[Suricata Eve JSON output](https://suricata.readthedocs.io/en/latest/output/eve/eve-json-format.html). \
[Learn more]({learnMoreLink}).',
      values: {
        learnMoreLink: '{config.docs.beats.filebeat}/filebeat-module-suricata.html'
      }
    }),
    //euiIconType: 'logoSuricata',
    artifacts: {
      dashboards: [{
        id: '69f5ae20-eb02-11e7-8f04-51231daa5b05',
        linkLabel: _i18n.i18n.translate('kbn.server.tutorials.suricataLogs.artifacts.dashboards.linkLabel', {
          defaultMessage: 'Suricata logs dashboard'
        }),
        isOverview: true
      }],
      exportedFields: {
        documentationUrl: '{config.docs.beats.filebeat}/exported-fields-suricata.html'
      }
    },
    completionTimeMinutes: 10,
    previewImagePath: '/plugins/kibana/home/tutorial_resources/suricata_logs/screenshot.png',
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
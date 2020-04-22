'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createDownloadServerRpm = exports.createDownloadServerDeb = exports.createDownloadServerOsx = exports.createEditConfig = undefined;
exports.createStartServerUnixSysv = createStartServerUnixSysv;
exports.createStartServerUnix = createStartServerUnix;
exports.createWindowsServerInstructions = createWindowsServerInstructions;

var _i18n = require('@kbn/i18n');

const createEditConfig = exports.createEditConfig = () => ({
  title: _i18n.i18n.translate('kbn.server.tutorials.apm.editConfig.title', {
    defaultMessage: 'Edit the configuration'
  }),
  textPre: _i18n.i18n.translate('kbn.server.tutorials.apm.editConfig.textPre', {
    defaultMessage: 'If you\'re using an X-Pack secured version of Elastic Stack, you must specify \
credentials in the `apm-server.yml` config file.'
  }),
  commands: ['output.elasticsearch:', '    hosts: ["<es_url>"]', '    username: <username>', '    password: <password>']
}); /*
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

const createStartServer = () => ({
  title: _i18n.i18n.translate('kbn.server.tutorials.apm.startServer.title', {
    defaultMessage: 'Start APM Server'
  }),
  textPre: _i18n.i18n.translate('kbn.server.tutorials.apm.startServer.textPre', {
    defaultMessage: 'The server processes and stores application performance metrics in Elasticsearch.'
  })
});

function createStartServerUnixSysv() {
  const START_SERVER = createStartServer();

  return {
    title: START_SERVER.title,
    textPre: START_SERVER.textPre,
    commands: ['service apm-server start']
  };
}

function createStartServerUnix() {
  const START_SERVER = createStartServer();

  return {
    title: START_SERVER.title,
    textPre: START_SERVER.textPre,
    commands: ['./apm-server -e']
  };
}

const createDownloadServerTitle = () => _i18n.i18n.translate('kbn.server.tutorials.apm.downloadServer.title', {
  defaultMessage: 'Download and unpack APM Server'
});

const createDownloadServerOsx = exports.createDownloadServerOsx = () => ({
  title: createDownloadServerTitle(),
  commands: ['curl -L -O https://artifacts.elastic.co/downloads/apm-server/apm-server-{config.kibana.version}-darwin-x86_64.tar.gz', 'tar xzvf apm-server-{config.kibana.version}-darwin-x86_64.tar.gz', 'cd apm-server-{config.kibana.version}-darwin-x86_64/']
});

const createDownloadServerDeb = exports.createDownloadServerDeb = () => ({
  title: createDownloadServerTitle(),
  commands: ['curl -L -O https://artifacts.elastic.co/downloads/apm-server/apm-server-{config.kibana.version}-amd64.deb', 'sudo dpkg -i apm-server-{config.kibana.version}-amd64.deb'],
  textPost: _i18n.i18n.translate('kbn.server.tutorials.apm.downloadServerTitle', {
    defaultMessage: 'Looking for the 32-bit packages? See the [Download page]({downloadPageLink}).',
    values: { downloadPageLink: '{config.docs.base_url}downloads/apm/apm-server' }
  })
});

const createDownloadServerRpm = exports.createDownloadServerRpm = () => ({
  title: createDownloadServerTitle(),
  commands: ['curl -L -O https://artifacts.elastic.co/downloads/apm-server/apm-server-{config.kibana.version}-x86_64.rpm', 'sudo rpm -vi apm-server-{config.kibana.version}-x86_64.rpm'],
  textPost: _i18n.i18n.translate('kbn.server.tutorials.apm.downloadServerRpm', {
    defaultMessage: 'Looking for the 32-bit packages? See the [Download page]({downloadPageLink}).',
    values: { downloadPageLink: '{config.docs.base_url}downloads/apm/apm-server' }
  })
});

function createWindowsServerInstructions() {
  const START_SERVER = createStartServer();

  return [{
    title: createDownloadServerTitle(),
    textPre: _i18n.i18n.translate('kbn.server.tutorials.apm.windowsServerInstructions.textPre', {
      defaultMessage: '1. Download the APM Server Windows zip file from the \
[Download page]({downloadPageLink}).\n2. Extract the contents of \
the zip file into {zipFileExtractFolder}.\n3. Rename the {apmServerDirectory} \
directory to `APM-Server`.\n4. Open a PowerShell prompt as an Administrator \
(right-click the PowerShell icon and select \
**Run As Administrator**). If you are running Windows XP, you might need to download and install \
PowerShell.\n5. From the PowerShell prompt, run the following commands to install APM Server as a Windows service:',
      values: {
        downloadPageLink: 'https://www.elastic.co/downloads/apm/apm-server',
        zipFileExtractFolder: '`C:\\Program Files`',
        apmServerDirectory: '`apm-server-{config.kibana.version}-windows`'
      }
    }),
    commands: [`cd 'C:\\Program Files\\APM-Server'`, `.\\install-service-apm-server.ps1`],
    textPost: _i18n.i18n.translate('kbn.server.tutorials.apm.windowsServerInstructions.textPost', {
      defaultMessage: 'Note: If script execution is disabled on your system, \
you need to set the execution policy for the current session \
to allow the script to run. For example: {command}.',
      values: {
        command: '`PowerShell.exe -ExecutionPolicy UnRestricted -File .\\install-service-apm-server.ps1`'
      }
    })
  }, createEditConfig(), {
    title: START_SERVER.title,
    textPre: START_SERVER.textPre,
    commands: ['Start-Service apm-server']
  }];
}